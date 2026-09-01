import React from 'react';

const features = [
  {
    icon: '01',
    title: 'Самостоятельное хранение',
    text: 'Полный контроль над ключами и активами без посредников, скрытых ограничений и сторонних сервисов.',
  },
  {
    icon: '02',
    title: 'Быстрые операции',
    text: 'Отправка, получение, обмен и покупка активов в одном интерфейсе — быстро и без лишних действий.',
  },
  {
    icon: '03',
    title: 'Защита по умолчанию',
    text: 'Безопасность заложена в продукт: пароль, биометрия и прозрачный контроль ключевых сценариев.',
  },
];

function FeatureGrid() {
  return (
    <section className="features wrapper" id="features">
      <div className="section-heading">
        <p className="section-kicker">Почему выбирают ATX</p>
        <h2>Надежный кошелек для повседневной работы с криптовалютой</h2>
      </div>

      <div className="features__grid">
        {features.map((feature) => (
          <article key={feature.title} className="feature-card">
            <span className="feature-card__icon">{feature.icon}</span>
            <h3>{feature.title}</h3>
            <p>{feature.text}</p>
          </article>
        ))}
      </div>
    </section>
  );
}

export default FeatureGrid;
