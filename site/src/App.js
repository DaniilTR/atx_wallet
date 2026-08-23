import './App.css';

import logo from './assets/image 4.png';
import heroDesktop from './assets/MacBook Pro 14_ - 2.png';
import screenRegister from './assets/iMockup - Google Pixel 8 Pro-2.png';
import screenLogin from './assets/iMockup - Google Pixel 8 Pro-3.png';
import screenWallet from './assets/iMockup - Google Pixel 8 Pro-4.png';
import screenMain from './assets/iMockup - Google Pixel 8 Pro (2).png';

const features = [
  {
    title: 'Самостоятельное хранение',
    text: 'Только вы контролируете ключи и доступ к активам. Без посредников и скрытых ограничений.',
    icon: '01',
  },
  {
    title: 'Быстрые операции',
    text: 'Отправка, получение, обмен и покупка криптовалюты в одном интерфейсе за несколько касаний.',
    icon: '02',
  },
  {
    title: 'Защита по умолчанию',
    text: 'Пароль, биометрия и прозрачная безопасность для спокойной работы с вашим портфелем.',
    icon: '03',
  },
];

const steps = [
  'Создайте новый кошелек за минуту',
  'Пополните баланс и получите персональный адрес',
  'Управляйте токенами, отправляйте и обменивайте активы',
];

function App() {
  return (
    <div className="landing">
      <div className="atx-glow atx-glow--one" />
      <div className="atx-glow atx-glow--two" />
      <div className="atx-glow atx-glow--three" />

      <header className="topbar wrapper">
        <a className="brand" href="#home" aria-label="ATX Wallet">
          <img src={logo} alt="ATX" />
          <span>ATX Wallet</span>
        </a>
        <nav className="menu">
          <a href="#features">Возможности</a>
          <a href="#security">Безопасность</a>
          <a href="#start">Начать</a>
        </nav>
      </header>

      <main>
        <section className="hero wrapper" id="home">
          <div className="hero__content">
            <p className="eyebrow">Кошелек для Web3 и DeFi</p>
            <h1>Свобода ваших финансов в одном ATX Wallet</h1>
            <p className="subtitle">
              Современный криптокошелек для хранения, обмена и управления активами.
              Создан для скорости, безопасности и полного контроля.
            </p>
            <div className="hero__actions">
              <button type="button" className="btn btn--primary">
                Создать новый кошелек
              </button>
              <button type="button" className="btn btn--ghost">
                У меня уже есть кошелек
              </button>
            </div>
            <div className="stats">
              <article>
                <strong>120K+</strong>
                <span>Пользователей</span>
              </article>
              <article>
                <strong>140+</strong>
                <span>Поддерживаемых активов</span>
              </article>
              <article>
                <strong>99.99%</strong>
                <span>Время доступности</span>
              </article>
            </div>
          </div>

          <div className="hero__visual">
            <img className="mockup-desktop" src={heroDesktop} alt="ATX Wallet на ноутбуке" />
          </div>
        </section>

        <section className="features wrapper" id="features">
          <h2>Сфокусирован на реальном использовании</h2>
          <div className="features__grid">
            {features.map((item) => (
              <article key={item.title} className="feature-card">
                <span className="feature-card__icon">{item.icon}</span>
                <h3>{item.title}</h3>
                <p>{item.text}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="showcase wrapper" aria-label="Интерфейсы приложения">
          <h2>Интерфейс, который не перегружает</h2>
          <p>
            Минималистичная темная тема, акцент на данных и действиях. Все ключевые сценарии доступны
            без лишних шагов.
          </p>
          <div className="showcase__row">
            <img src={screenMain} alt="Главный экран кошелька" />
            <img src={screenWallet} alt="Экран активов" />
            <img src={screenLogin} alt="Экран входа" />
            <img src={screenRegister} alt="Экран регистрации" />
          </div>
        </section>

        <section className="security wrapper" id="security">
          <div className="security__box">
            <h2>Безопасность как часть UX</h2>
            <ul>
              {steps.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ul>
            <a className="btn btn--primary" href="#start">
              Открыть ATX Wallet
            </a>
          </div>
        </section>
      </main>

      <footer className="footer wrapper" id="start">
        <p>ATX Wallet · Ваш личный доступ к крипторынку</p>
      </footer>
    </div>
  );
}

export default App;
