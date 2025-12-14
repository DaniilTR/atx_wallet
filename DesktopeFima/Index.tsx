import React from "react";
import { BalanceSection } from "./BalanceSection";
import { TransactionHistorySection } from "./TransactionHistorySection";
import image from "./image.svg";
import vector2 from "./vector-2.svg";
import vector3 from "./vector-3.svg";
import vector4 from "./vector-4.svg";
import vector from "./vector.svg";

export const MacbookPro = (): JSX.Element => {
  const tokenData = {
    name: "TestBNB",
    symbol: "TBNB",
    amount: "3000",
  };

  const navigationIcons = [
    {
      src: vector2,
      alt: "Home",
      top: "4.89%",
      left: "2.18%",
      width: "3.84%",
      height: "5.50%",
    },
    {
      src: vector4,
      alt: "Analytics",
      top: "29.43%",
      left: "0",
      width: "4.56%",
      height: "7.33%",
    },
    {
      src: vector3,
      alt: "Transactions",
      top: "42.36%",
      left: "2.25%",
      width: "4.10%",
      height: "6.82%",
    },
  ];

  const decorativeBlurs = [
    {
      top: "834px",
      left: "547px",
      width: "114px",
      height: "118px",
      bg: "bg-[#9117d8cc]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[25px]",
    },
    {
      top: "368px",
      left: "1455px",
      width: "114px",
      height: "118px",
      bg: "bg-[#3b99f4]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[25px]",
    },
    {
      top: "692px",
      left: "72px",
      width: "198px",
      height: "134px",
      bg: "bg-[#331cc9]",
      borderRadius: "rounded-[99px/67px]",
      rotate: "rotate-[27.47deg]",
      blur: "blur-[25px]",
    },
    {
      top: "645px",
      left: "1086px",
      width: "114px",
      height: "118px",
      bg: "bg-[#3b99f4]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[25px]",
    },
    {
      top: "0",
      left: "0",
      width: "114px",
      height: "118px",
      bg: "bg-[#9117d8cc]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[25px]",
    },
    {
      top: "-50px",
      left: "824px",
      width: "114px",
      height: "118px",
      bg: "bg-[#331cc9]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[25px]",
    },
    {
      top: "175px",
      left: "416px",
      width: "114px",
      height: "118px",
      bg: "bg-[#3b99f4]",
      borderRadius: "rounded-[57px/59px]",
      blur: "blur-[35px]",
    },
  ];

  return (
    <div className="bg-[#14191e] overflow-hidden w-full min-w-[1512px] h-[982px] relative">
      {decorativeBlurs.map((blur, index) => (
        <div
          key={index}
          className={`absolute ${blur.bg} ${blur.borderRadius} ${blur.blur} ${blur.rotate || ""}`}
          style={{
            top: blur.top,
            left: blur.left,
            width: blur.width,
            height: blur.height,
          }}
        />
      ))}

      <aside
        className="absolute top-0 left-0 w-[125px] h-[982px] bg-[#3a3f4a4a]"
        role="navigation"
        aria-label="Main navigation"
      >
        <nav>
          {navigationIcons.map((icon, index) => (
            <button
              key={index}
              className="absolute"
              style={{
                width: icon.width,
                height: icon.height,
                top: icon.top,
                left: icon.left,
              }}
              aria-label={icon.alt}
            >
              <img className="w-full h-full" alt={icon.alt} src={icon.src} />
            </button>
          ))}

          <button
            className="absolute w-[3.84%] h-[5.50%] top-[19.45%] left-[2.25%]"
            aria-label="Wallet"
          >
            <img
              className="absolute w-[46.14%] h-[46.17%] top-0 left-[53.86%]"
              alt="Wallet icon overlay"
              src={vector}
            />
            <img
              className="absolute w-[89.69%] h-[89.73%] top-[10.27%] left-0"
              alt="Wallet icon"
              src={image}
            />
          </button>
        </nav>
      </aside>

      <main>
        <BalanceSection />
        <TransactionHistorySection />

        <section
          className="absolute top-[516px] left-[231px]"
          aria-label="Token information"
        >
          <h2 className="inline-block [font-family:'Poppins-Medium',Helvetica] font-medium text-white text-[40px] tracking-[0] leading-[normal]">
            {tokenData.name}
          </h2>

          <span className="inline-block ml-[210px] w-[106px] [font-family:'Poppins-Regular',Helvetica] font-normal text-[#a6a6a6] text-[40px] tracking-[0] leading-[normal] whitespace-nowrap">
            {tokenData.symbol}
          </span>

          <span className="inline-block ml-[130px] w-[104px] [font-family:'Poppins-Regular',Helvetica] text-[#a6a6a6] text-[40px] font-normal tracking-[0] leading-[normal] whitespace-nowrap">
            {tokenData.amount}
          </span>
        </section>
      </main>
    </div>
  );
};
