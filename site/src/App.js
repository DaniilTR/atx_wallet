import './App.css';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Header from './components/Header';
import Footer from './components/Footer';
import HomePage from './pages/HomePage';
import DownloadPage from './pages/DownloadPage';
import SecurityPage from './pages/SecurityPage';
import DocsPage from './pages/DocsPage';

function App() {
  return (
    <Router>
      <div className="landing-page">
        <div className="background-glow background-glow--violet" />
        <div className="background-glow background-glow--cyan" />
        <div className="background-glow background-glow--purple" />

        <Header />

        <main>
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/download" element={<DownloadPage />} />
            <Route path="/security" element={<SecurityPage />} />
            <Route path="/docs" element={<DocsPage />} />
          </Routes>
        </main>

        <Footer />
      </div>
    </Router>
  );
}

export default App;
