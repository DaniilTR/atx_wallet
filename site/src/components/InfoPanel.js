import React from 'react';
import screenMain from '../assets/iMockup - Google Pixel 8 Pro (2).png';
import screenWallet from '../assets/iMockup - Google Pixel 8 Pro-4.png';
import screenLogin from '../assets/iMockup - Google Pixel 8 Pro-3.png';
import screenRegister from '../assets/iMockup - Google Pixel 8 Pro-2.png';

const screenSet = [screenMain, screenWallet, screenLogin, screenRegister];

function InfoPanel() {
  return (
    <section className="showcase wrapper" id="wallet" aria-label="Интерфейсы приложения">
      <div className="section-heading section-heading--left">
        <p className="section-kicker">Интерфейс</p>
        <h2>Продукт, в котором удобно каждый день</h2>
      </div>

      <div className="showcase__row">
        {screenSet.map((screen, index) => (
          <img key={screen + index} src={screen} alt={`Скриншот интерфейса ${index + 1}`} />
        ))}
      </div>
    </section>
  );
}

export default InfoPanel;
