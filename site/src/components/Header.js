import React from 'react';
import { Link } from 'react-router-dom';
import logo from '../assets/image 4.png';

const navigation = [
  { label: 'Главная', href: '/' },
  { label: 'Скачать', href: '/download' },
  { label: 'Безопасность', href: '/security' },
  { label: 'Документы', href: '/docs' },
];

function Header() {
  return (
    <header className="topbar wrapper" aria-label="Основная навигация">
      <Link className="brand" to="/" aria-label="ATX Wallet home">
        <img src={logo} alt="ATX Wallet логотип" />
        <span>ATX Wallet</span>
      </Link>

      <nav className="menu" aria-label="Навигация по страницам">
        {navigation.map((item) => (
          <Link key={item.href} to={item.href}>
            {item.label}
          </Link>
        ))}
      </nav>

      <Link to="/download" className="header-cta">
        Открыть приложение
      </Link>
    </header>
  );
}

export default Header;
