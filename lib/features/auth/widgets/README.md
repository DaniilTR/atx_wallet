# Auth UI widgets

This folder contains:

- `AnimatedNeonBackground`: Fullscreen animated gradient with slow floating neon blobs, inspired by the attached web CSS/HTML.
- `GlassCard`: Reusable glassmorphism container using `BackdropFilter` blur, translucent fill and subtle border.

Usage example:

```
Stack(
  children: const [AnimatedNeonBackground()],
)
```

Wrap your forms with `GlassCard` to achieve the frosted glass effect. Both widgets are platform-neutral and adapt to any screen size.