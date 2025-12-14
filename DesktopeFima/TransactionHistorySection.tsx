import React from "react";
import vector22 from "./vector-22.svg";
import vector23 from "./vector-23.svg";

interface Transaction {
  id: string;
  name: string;
  symbol: string;
  amount: number;
  icon: string;
}

export const TransactionHistorySection = (): JSX.Element => {
  const transactions: Transaction[] = [
    {
      id: "1",
      name: "TestBNB",
      symbol: "TBNB",
      amount: 3000,
      icon: vector23,
    },
    {
      id: "2",
      name: "Dogecoin",
      symbol: "DOGE",
      amount: 4000,
      icon: vector22,
    },
    {
      id: "3",
      name: "",
      symbol: "",
      amount: 0,
      icon: "",
    },
    {
      id: "4",
      name: "",
      symbol: "",
      amount: 0,
      icon: "",
    },
  ];

  return (
    <section className="absolute top-[483px] left-[111px] w-[1388px] h-[465px]">
      {transactions.map((transaction, index) => (
        <div
          key={transaction.id}
          className="absolute left-[22px] w-[1363px] h-[85px] bg-[#211e41] rounded-[15px] shadow-[inset_0px_4px_34px_#35325abf]"
          style={{ top: `${23 + index * 119}px` }}
        >
          {transaction.icon && (
            <img
              className="absolute w-[58px] h-[58px] top-[14px] left-[25px]"
              alt={`${transaction.name} icon`}
              src={transaction.icon}
            />
          )}
          {transaction.name && (
            <>
              <div className="absolute top-[6px] left-[98px] [font-family:'Poppins-Medium',Helvetica] font-medium text-white text-[40px] tracking-[0] leading-[normal]">
                {transaction.name}
              </div>
              <div className="absolute top-[10px] left-[308px] [font-family:'Poppins-Regular',Helvetica] font-normal text-[#a6a6a6] text-[40px] tracking-[0] leading-[normal]">
                {transaction.symbol}
              </div>
              <div className="absolute top-[12px] left-[438px] [font-family:'Poppins-Regular',Helvetica] font-normal text-[#a6a6a6] text-[40px] tracking-[0] leading-[normal] whitespace-nowrap">
                {transaction.amount}
              </div>
            </>
          )}
        </div>
      ))}
    </section>
  );
};
