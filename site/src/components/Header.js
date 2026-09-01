import React from 'react';
import logo from '../assets/image 4.png';

const navigation = [
  { label: 'Возможности', href: '#features' },
  { label: 'Безопасность', href: '#security' },
  { label: 'Как работает', href: '#how-it-works' },
  { label: 'Портфолио', href: '#wallet' },
];

function Header() {
  return (
    <header className="topbar wrapper" aria-label="Основная навигация">
      <a className="brand" href="#home" aria-label="ATX Wallet home">
        <img src={logo} alt="ATX Wallet логотип" />
        <span>ATX Wallet</span>
      </a>

      <nav className="menu" aria-label="Навигация по секциям">
        {navigation.map((item) => (
          <a key={item.href} href={item.href}>
            {item.label}
          </a>
        ))}
      </nav>

      <button type="button" className="header-cta">
        Открыть приложение
      </button>
    </header>
  );
}

export default Header;
