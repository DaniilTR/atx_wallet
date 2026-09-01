import React from 'react';
import heroDesktop from '../assets/iMockup - Google Pixel 8 Pro.png';

const stats = [
  { value: '120K+', label: 'пользователей' },
  { value: '140+', label: 'поддерживаемых активов' },
  { value: '100%', label: 'время доступности' },
];

function HeroSection() {
  return (
    <section className="hero wrapper" id="home">
      <div className="hero__content">
        <p className="eyebrow">Криптокошелек нового поколения</p>
        <h1>Свобода ваших финансов в одном ATX Wallet</h1>
        <p className="subtitle">
          Современный кошелек для хранения, обмена и управления цифровыми активами.
          Принимайте решения быстро, безопасно и без лишних посредников.
        </p>

        <div className="hero__actions">
          <button type="button" className="btn btn--primary">
            Создать новый кошелек
          </button>
          <button type="button" className="btn btn--secondary">
            У меня уже есть кошелек
          </button>
        </div>

        <div className="stats" aria-label="Основные показатели">
          {stats.map((item) => (
            <article key={item.label} className="stat-card">
              <strong>{item.value}</strong>
              <span>{item.label}</span>
            </article>
          ))}
        </div>
      </div>

      <div className="hero__visual" aria-label="Скриншот приложения на ноутбуке">
        <div className="orb orb--left" />
        <div className="orb orb--right" />
        <img className="mockup-desktop" src={heroDesktop} alt="ATX Wallet на ноутбуке" />
      </div>
    </section>
  );
}

export default HeroSection;
