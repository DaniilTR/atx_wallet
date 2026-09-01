import React from 'react';
// eslint-disable-next-line no-unused-vars
import FrameDecor from '../assets/Frame 10.png';
import GlassDecor from '../assets/gradient glass (11).png';

const securityPillars = [
  {
    title: 'Локальные ключи',
    text: 'Криптографический материал хранится на устройстве пользователя и не передаётся на сервер.',
  },
  {
    title: 'Защита паролем',
    text: 'Доступ к защищённому хранилищу основан на локальной аутентификации и криптографическом ключе.',
  },
  {
    title: 'Биометрия',
    text: 'Поддерживаются системные механизмы владельца устройства для дополнительного уровня защиты.',
  },
  {
    title: 'Прозрачная архитектура',
    text: 'Приложение использует публичные RPC и API без скрытого приватного доступа к пользовательским данным.',
  },
];

const flow = [
  'Пользователь вводит пароль для разблокировки защищённого хранилища.',
  'Система расшифровывает локальные данные и восстанавливает ключи на устройстве.',
  'Публичные адреса и данные проверяются по API, но приватные данные остаются локальными.',
  'Пользователь управляет кошельком без передачи seed-фразы каким-либо сторонним сервисам.',
];

function SecurityPage() {
  return (
    <div className="page-shell wrapper">
      {/* Декоративные элементы */}
      <img src={FrameDecor} alt="" className="decorative-frame decorative-frame--page-top-left" />
      <img src={GlassDecor} alt="" className="gradient-glass-decor gradient-glass-decor--bottom-right-sec" />

      <section className="page-intro">
        <p className="section-kicker">Безопасность</p>
        <h1>Контроль над активами остаётся только у пользователя.</h1>
        <p>
          Мы строим продукт вокруг принципа self-custody: приложение помогает управлять капиталом, но не владеет ключами вместо клиента.
        </p>
      </section>

      <div className="two-column-layout">
        <div className="info-card">
          <h3>Основные принципы</h3>
          <ul className="feature-points">
            {securityPillars.map((item) => (
              <li key={item.title}> 
                <strong>{item.title}</strong>
                <span>{item.text}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="info-card gradient-card">
          <h3>Как это работает</h3>
          <ol className="number-list">
            {flow.map((step, index) => (
              <li key={step}><span>{index + 1}</span>{step}</li>
            ))}
          </ol>
        </div>
      </div>
    </div>
  );
}

export default SecurityPage;
