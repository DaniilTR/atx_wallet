import React from 'react';
// eslint-disable-next-line no-unused-vars
import FrameDecor1 from '../assets/Frame 10-1.png';
import GlassDecor from '../assets/gradient glass (21).png';

const appFeatures = [
  'Мгновенный доступ к кошельку и безопасному хранению масла/coin-активов',
  'Поддержка Ethereum, BTC, USDT и базовых Web3 сценариев',
  'Локальная криптография и контроль над ключами без стороннего доступа',
  'Мультитач/UX-дизайн под смартфоны и десктоп',
];

const platforms = [
  { title: 'Android', badge: 'APK / Google Play', description: 'Стабильная сборка для мобильных устройств и тестовых релизов.' },
  { title: 'Desktop', badge: 'Windows / macOS / Linux', description: 'Версия для мощных сценариев и продвинутой работы с крипто-активами.' },
  { title: 'Web security', badge: 'Ссылка / docs', description: 'Документы, политика конфиденциальности и публичные инструкции для пользователей.' },
];

function DownloadPage() {
  return (
    <div className="page-shell wrapper">
      {/* Декоративные элементы */}
      <img src={FrameDecor1} alt="" className="decorative-frame decorative-frame--page-top-left" />
      <img src={GlassDecor} alt="" className="gradient-glass-decor gradient-glass-decor--top-center" />

      <section className="page-intro">
        <p className="section-kicker">Скачать</p>
        <h1>ATX Wallet доступен в нескольких вариантах запуска.</h1>
        <p>
          Приложение ориентировано на безопасное хранение, локальные ключи и быстрый доступ к основным активам без перегруженного интерфейса.
        </p>
      </section>

      <div className="download-grid">
        {platforms.map((platform) => (
          <article key={platform.title} className="info-card download-card">
            <span className="info-card__badge">{platform.badge}</span>
            <h3>{platform.title}</h3>
            <p>{platform.description}</p>
            <button type="button" className="btn btn--primary">Получить доступ</button>
          </article>
        ))}
      </div>

      <section className="feature-list-block">
        <div className="feature-list-block__text">
          <p className="section-kicker">Почему это удобно</p>
          <h2>Сценарии использования выстроены вокруг привычного UX.</h2>
        </div>

        <ul className="check-list">
          {appFeatures.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}

export default DownloadPage;
