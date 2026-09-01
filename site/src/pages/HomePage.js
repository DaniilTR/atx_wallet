import React from 'react';
import HeroSection from '../components/HeroSection';
import FeatureGrid from '../components/FeatureGrid';
import InfoPanel from '../components/InfoPanel';
// eslint-disable-next-line no-unused-vars
import GlassDecor from '../assets/Frame 10-2.png';
import GlassDecor1 from '../assets/gradient glass (11).png';
import FrameDecor1 from '../assets/Frame 10-1.png';

function HomePage() {
  return (
    <>
      {/* Декоративные элементы */}
      <img src={GlassDecor} alt="" className="decorative-frame decorative-frame--hero-top-right" />
      <img src={GlassDecor1} alt="" className="gradient-glass-decor gradient-glass-decor--bottom-right" />
      <img src={FrameDecor1} alt="" className="decorative-frame decorative-frame--page-top-left-home" />
      <HeroSection />
      <FeatureGrid />
      <InfoPanel /> 

      <section className="cta-section wrapper">
        <div className="cta-panel">
          <div>
            <p className="section-kicker">Начать работу</p>
            <h2>Управляйте активами без лишнего шума и с полным контролем.</h2>
          </div>

          <div className="cta-panel__actions">
            <a href="/download" className="btn btn--primary">Скачать приложение</a>
            <a href="/security" className="btn btn--secondary">Безопасность</a>
          </div>
        </div>
      </section>
    </>
  );
}

export default HomePage;
