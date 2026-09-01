import React from 'react';

function Footer() {
  return (
    <footer className="footer wrapper" id="start">
      <div className="footer__line" />
      <div className="footer__content">
        <div>
          <p className="footer__title">ATX Wallet</p>
          <p className="footer__text">Ваш личный доступ к криптоактивам в одном интерфейсе.</p>
        </div>

        <button type="button" className="btn btn--primary footer__button">
          Подключить кошелек
        </button>
      </div>
    </footer>
  );
}

export default Footer;
