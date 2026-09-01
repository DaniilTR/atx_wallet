import React from 'react';
// eslint-disable-next-line no-unused-vars
import FrameDecor1 from '../assets/Frame 10-1.png';
import GlassDecor from '../assets/gradient glass (21).png';

const docs = [
  {
    title: 'Политика конфиденциальности',
    href: 'https://github.com/DaniilTR/atx_wallet/blob/ab8847c6e2830d1ebc4cc180468b1209332309d4/docs/privacy-policy.md',
    description: 'Описание того, какие данные обрабатываются локально, а какие выводятся только в публичный контекст.',
  },
  {
    title: 'Условия использования',
    href: 'https://github.com/DaniilTR/atx_wallet/blob/ab8847c6e2830d1ebc4cc180468b1209332309d4/docs/terms-of-use.md',
    description: 'Правила использования продукта, ограничения ответственности и рекомендации по безопасной работе с кошельком.',
  },
  {
    title: 'Архитектура проекта',
    href: 'https://github.com/DaniilTR/atx_wallet/blob/ab8847c6e2830d1ebc4cc180468b1209332309d4/for_project.md',
    description: 'Документ, раскрывающий стек, клиентскую логику, хранение данных, RPC, маршрутизацию и ключевые сценарии.',
  },
];

function DocsPage() {
  return (
    <div className="page-shell wrapper">
      {/* Декоративные элементы */}
      <img src={FrameDecor1} alt="" className="decorative-frame decorative-frame--page-top-left" />
      <img src={GlassDecor} alt="" className="gradient-glass-decor gradient-glass-decor--bottom-right" />

      <section className="page-intro">
        <p className="section-kicker">Документы</p>
        <h1>Публичная документация проекта и правила работы с продуктом.</h1>
      </section>

      <div className="docs-grid">
        {docs.map((doc) => (
          <article key={doc.title} className="info-card doc-card">
            <h3>{doc.title}</h3>
            <p>{doc.description}</p>
            <a href={doc.href} target="_blank" rel="noreferrer" className="btn btn--secondary">Открыть документ</a>
          </article>
        ))}
      </div>
    </div>
  );
}

export default DocsPage;
