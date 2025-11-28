document.addEventListener('DOMContentLoaded', () => {
	const tabs = document.querySelectorAll('.tab');
	const loginForm = document.getElementById('login-form');
	const signupForm = document.getElementById('signup-form');

	tabs.forEach(tab => {
		tab.addEventListener('click', () => {
			tabs.forEach(t => t.classList.remove('active'));
			tab.classList.add('active');
			const target = tab.dataset.target;
			if (target === 'login') {
				loginForm.classList.add('active');
				signupForm.classList.remove('active');
				signupForm.setAttribute('hidden', '');
				loginForm.removeAttribute('hidden');
			} else {
				signupForm.classList.add('active');
				loginForm.classList.remove('active');
				loginForm.setAttribute('hidden', '');
				signupForm.removeAttribute('hidden');
			}
		});
	});

	document.querySelectorAll('[data-action="toggle-password"]').forEach(btn => {
		btn.addEventListener('click', () => {
			const input = document.getElementById(btn.dataset.target);
			if (!input) return;
			const isPwd = input.type === 'password';
			input.type = isPwd ? 'text' : 'password';
			btn.setAttribute('aria-label', isPwd ? 'Скрыть пароль' : 'Показать пароль');
		});
	});

	const demoSubmit = (e) => {
		e.preventDefault();
		const form = e.target;
		const data = new FormData(form);
		const payload = Object.fromEntries(data.entries());
		// простая демонстрация
		console.log('Form submit:', form.id, payload);
		const btn = form.querySelector('.primary');
		const initial = btn.textContent;
		btn.disabled = true;
		btn.textContent = 'Обработка…';
		setTimeout(() => {
			btn.disabled = false;
			btn.textContent = initial;
			alert('Демо: данные приняты (см. консоль)');
		}, 800);
	};

	loginForm.addEventListener('submit', demoSubmit);
	signupForm.addEventListener('submit', demoSubmit);

	document.getElementById('wallet-connect').addEventListener('click', () => {
		alert('Демо: здесь будет подключение кошелька (WalletConnect/QR).');
	});
	document.getElementById('forgot-btn').addEventListener('click', () => {
		alert('Демо: восстановление пароля.');
	});
});
