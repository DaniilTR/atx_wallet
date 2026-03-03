package com.example.atx_wallet

import android.content.Context
import android.util.Base64
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.SecureRandom
import java.util.concurrent.Executor
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterFragmentActivity() {
	private val CHANNEL = "com.atx/biometric"
	private val PREFS_NAME = "atx_biometric_prefs"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"isAvailable" -> result.success(isBiometricAvailable())
				"enableFaceAuth" -> {
					val userId = call.argument<String>("userId") ?: ""
					val password = call.argument<String>("password")
					// MethodChannel: enableFaceAuth called for userId (logging removed in production)
					handleEnableFaceAuth(userId, password, result)
				}
				"authenticate" -> {
					val userId = call.argument<String>("userId") ?: ""
					handleAuthenticate(userId, result)
				}
				"disableFaceAuth" -> {
					val userId = call.argument<String>("userId") ?: ""
					handleDisable(userId, result)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun isBiometricAvailable(): Boolean {
		val biometricManager = BiometricManager.from(this)
		return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
	}

	private fun handleEnableFaceAuth(userId: String, password: String?, result: MethodChannel.Result) {
		try {
			// Generate a random DEK (kept only in native). If a password/secret is provided,
			// encrypt that secret with DEK and store the ciphertext in prefs so native can later
			// decrypt it after unwrapping DEK. We DO NOT expose raw DEK to Dart.
			val dek = ByteArray(32)
			SecureRandom().nextBytes(dek)

			// ensure KEK exists in AndroidKeyStore
			val alias = keyAliasFor(userId)
			ensureKeyExists(alias)

			// Prepare to wrap (encrypt) DEK with KEK, but perform the actual wrap inside
			// BiometricPrompt after the user authenticates so KeyStore receives an auth token.
			val kek = getSecretKey(alias)
			val wrapCipher = Cipher.getInstance("AES/GCM/NoPadding")
			wrapCipher.init(Cipher.ENCRYPT_MODE, kek)

			val prefs = getEncryptedPrefs()
			val executor: Executor = ContextCompat.getMainExecutor(this)
			val prompt = BiometricPrompt(this as FragmentActivity, executor, object : BiometricPrompt.AuthenticationCallback() {
				override fun onAuthenticationSucceeded(resultPrompt: BiometricPrompt.AuthenticationResult) {
					try {
							val c = resultPrompt.cryptoObject?.cipher ?: wrapCipher
							val wrappedDek = c.doFinal(dek)
							val wrappedDekIv = c.iv

							// store wrapped dek and iv into EncryptedSharedPreferences
							prefs.edit().putString("wrapped_dek_$userId", Base64.encodeToString(wrappedDek, Base64.NO_WRAP)).apply()
							prefs.edit().putString("wrapped_dek_iv_$userId", Base64.encodeToString(wrappedDekIv, Base64.NO_WRAP)).apply()

							// If caller provided a password/secret, encrypt it with DEK and store ciphertext+iv
							if (password != null) {
							val secretBytes = password.toByteArray(Charsets.UTF_8)
							val secretCipher = Cipher.getInstance("AES/GCM/NoPadding")
							val dekKey = SecretKeySpec(dek, "AES")
							secretCipher.init(Cipher.ENCRYPT_MODE, dekKey)
							val secretCiphertext = secretCipher.doFinal(secretBytes)
							val secretIv = secretCipher.iv
							prefs.edit().putString("secret_cipher_$userId", Base64.encodeToString(secretCiphertext, Base64.NO_WRAP)).apply()
							prefs.edit().putString("secret_iv_$userId", Base64.encodeToString(secretIv, Base64.NO_WRAP)).apply()
							java.util.Arrays.fill(secretBytes, 0)
						}

							// zeroize DEK and return only a success marker to Dart
							java.util.Arrays.fill(dek, 0)
							val map: HashMap<String, Any> = HashMap()
							map["enabled"] = true
							// Do NOT return wrapped DEK/IV to Dart to avoid leaking sensitive material
							result.success(map)
					} catch (e: Exception) {
							// enableFaceAuth failed (error details suppressed in production)
							result.error("enable_error", e.toString(), null)
					}
				}

				override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
					result.error("auth_error", errString.toString(), null)
				}

				override fun onAuthenticationFailed() {
					result.error("auth_failed", "Biometric auth failed", null)
				}
			})

			val info = BiometricPrompt.PromptInfo.Builder()
				.setTitle("Сканирование лица")
				.setSubtitle("Подтвердите личность для включения быстрого входа")
				.setNegativeButtonText("Отмена")
				.build()

			prompt.authenticate(info, BiometricPrompt.CryptoObject(wrapCipher))
		} catch (e: Exception) {
			// enableFaceAuth failed (error details suppressed in production)
			// Return a more descriptive error string back to Dart (avoid null message)
			result.error("enable_error", e.toString(), null)
		}
	}

	private fun handleAuthenticate(userId: String, result: MethodChannel.Result) {
		try {
			val prefs = getEncryptedPrefs()
			val wrappedB64 = prefs.getString("wrapped_dek_$userId", null)
			val ivB64 = prefs.getString("wrapped_dek_iv_$userId", null)
			if (wrappedB64 == null || ivB64 == null) {
				result.error("no_wrapped_dek", "No wrapped DEK for user", null)
				return
			}

			val wrapped = Base64.decode(wrappedB64, Base64.NO_WRAP)
			val iv = Base64.decode(ivB64, Base64.NO_WRAP)

			val alias = keyAliasFor(userId)
			val key = getSecretKey(alias)

			val cipher = Cipher.getInstance("AES/GCM/NoPadding")
			val spec = GCMParameterSpec(128, iv)
			cipher.init(Cipher.DECRYPT_MODE, key, spec)

			val executor: Executor = ContextCompat.getMainExecutor(this)
			val prompt = BiometricPrompt(this as FragmentActivity, executor, object : BiometricPrompt.AuthenticationCallback() {
				override fun onAuthenticationSucceeded(resultPrompt: BiometricPrompt.AuthenticationResult) {
						try {
							val c = resultPrompt.cryptoObject?.cipher ?: cipher
							val dek = c.doFinal(wrapped)
						val prefs = getEncryptedPrefs()
						val secretCipherB64 = prefs.getString("secret_cipher_$userId", null)
						val secretIvB64 = prefs.getString("secret_iv_$userId", null)
						if (secretCipherB64 != null && secretIvB64 != null) {
							val secretCiphertext = Base64.decode(secretCipherB64, Base64.NO_WRAP)
							val secretIv = Base64.decode(secretIvB64, Base64.NO_WRAP)
							val dekKey = SecretKeySpec(dek, "AES")
							val secretDecCipher = Cipher.getInstance("AES/GCM/NoPadding")
							val secretSpec = GCMParameterSpec(128, secretIv)
							secretDecCipher.init(Cipher.DECRYPT_MODE, dekKey, secretSpec)
							val secretPlain = secretDecCipher.doFinal(secretCiphertext)
							val secretStr = String(secretPlain, Charsets.UTF_8)
							java.util.Arrays.fill(secretPlain, 0)
							java.util.Arrays.fill(dek, 0)
							val map: HashMap<String, Any?> = HashMap()
							map["secret"] = secretStr
							map["fallback"] = false
							result.success(map)
						} else {
							java.util.Arrays.fill(dek, 0)
							val map: HashMap<String, Any?> = HashMap()
							map["dek"] = null
							map["fallback"] = false
							result.success(map)
						}
						} catch (e: Exception) {
							result.error("primary_unwrap_failed", "Primary unwrap failed; require app password", null)
							return
						}
				}

				override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
					result.error("auth_error", errString.toString(), null)
				}

				override fun onAuthenticationFailed() {
					result.success(null)
				}
			})

			val info = BiometricPrompt.PromptInfo.Builder()
				.setTitle("Сканирование лица")
				.setSubtitle("Подтвердите личность")
				.setNegativeButtonText("Отмена")
				.build()

			prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
		} catch (e: Exception) {
			result.error("authenticate_error", e.message, null)
		}
	}

	private fun getEncryptedPrefs(): SharedPreferences {
		val masterKey = MasterKey.Builder(this)
			.setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
			.build()
		return EncryptedSharedPreferences.create(
			this,
			PREFS_NAME,
			masterKey,
			EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
			EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
		)
	}

	private fun handleDisable(userId: String, result: MethodChannel.Result) {
		try {
			val prefs = getEncryptedPrefs()
			prefs.edit().remove("wrapped_dek_$userId").apply()
			prefs.edit().remove("wrapped_dek_iv_$userId").apply()
			val alias = keyAliasFor(userId)
			val ks = KeyStore.getInstance("AndroidKeyStore")
			ks.load(null)
			ks.deleteEntry(alias)
			result.success(true)
		} catch (e: Exception) {
			result.error("disable_error", e.message, null)
		}
	}

	private fun keyAliasFor(userId: String) = "atx_biometric_key_$userId"

	private fun ensureKeyExists(alias: String) {
		val ks = KeyStore.getInstance("AndroidKeyStore")
		ks.load(null)
		if (!ks.containsAlias(alias)) {
			val kgen = KeyGenerator.getInstance("AES", "AndroidKeyStore")
			val specBuilder = android.security.keystore.KeyGenParameterSpec.Builder(
				alias,
				android.security.keystore.KeyProperties.PURPOSE_ENCRYPT or android.security.keystore.KeyProperties.PURPOSE_DECRYPT
					).setBlockModes(android.security.keystore.KeyProperties.BLOCK_MODE_GCM)
				.setEncryptionPaddings(android.security.keystore.KeyProperties.ENCRYPTION_PADDING_NONE)
					.setUserAuthenticationRequired(true)
						.setUserAuthenticationValidityDurationSeconds(0)
						.setInvalidatedByBiometricEnrollment(true)

					try {
						specBuilder.setIsStrongBoxBacked(true)
					} catch (sb: Exception) {
						// not available or not supported on this device/SDK - ignore
					}

			kgen.init(specBuilder.build())
			kgen.generateKey()
		}
	}

	private fun getSecretKey(alias: String): SecretKey {
		val ks = KeyStore.getInstance("AndroidKeyStore")
		ks.load(null)
		val entry = ks.getEntry(alias, null) as KeyStore.SecretKeyEntry
		return entry.secretKey
	}
}
