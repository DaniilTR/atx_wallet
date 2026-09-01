import './App.css';
import Header from './components/Header';
import HeroSection from './components/HeroSection';
import FeatureGrid from './components/FeatureGrid';
import InfoPanel from './components/InfoPanel';
import Footer from './components/Footer';

function App() {
  return (
    <div className="landing-page">
      <div className="background-glow background-glow--violet" />
      <div className="background-glow background-glow--cyan" />
      <div className="background-glow background-glow--purple" />

      <Header />

      <main>
        <HeroSection />
        <FeatureGrid />
        <InfoPanel />
      </main>

      <Footer />
    </div>
  );
}

export default App;
