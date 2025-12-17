import React from "react";
import group from "./group.png";
import image from "./image.png";
import path2 from "./path-2.svg";
import path3 from "./path-3.svg";
import path4 from "./path-4.svg";
import path5 from "./path-5.svg";
import path6 from "./path-6.svg";
import path7 from "./path-7.svg";
import path from "./path.svg";
import vector5 from "./vector-5.svg";
import vector7 from "./vector-7.svg";
import vector8 from "./vector-8.svg";
import vector9 from "./vector-9.svg";
import vector10 from "./vector-10.svg";
import vector11 from "./vector-11.svg";
import vector12 from "./vector-12.svg";
import vector13 from "./vector-13.svg";
import vector14 from "./vector-14.svg";
import vector17 from "./vector-17.svg";
import vector18 from "./vector-18.svg";
import vector19 from "./vector-19.svg";
import vector20 from "./vector-20.svg";
import vector21 from "./vector-21.svg";

const recentActivities = [
  {
    text: "Перевод:  100$ на ",
    address: "0xF08...43v334Fj73",
    date: " от 12.11",
  },
  { text: "Покупка: 0.3 IMX  от 12.11.2025", address: null, date: null },
  {
    text: "Вход: На устройстве android от 12.11.2025",
    address: null,
    date: null,
  },
  {
    text: "Перевод: 100$ на ",
    address: "0xF08...43v334Fj73",
    date: " от 12.11",
  },
];

const months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const yAxisLabels = ["17500", "14000", "10500", "7000", "3500", "0"];

const actionButtons = [
  { label: "SEND", icon: path, icon2: path2, left: "316px" },
  { label: "Receive", icon: path5, icon2: path6, left: "547px" },
  { label: "loan", icon: path7, icon2: null, left: "781px" },
  { label: "Topup", icon: path, icon2: path2, left: "1015px" },
];

export const BalanceSection = (): JSX.Element => {
  return (
    <section className="absolute -top-px left-[124px] w-[1389px] h-[485px] bg-[#ffffff13] rounded-[10px] overflow-hidden border-[none] shadow-[inset_1.04px_0.97px_4.24px_#ffffff22,inset_1.97px_1.84px_8.48px_#ffffff22,-1.86px_-1.73px_12px_-8px_#00000026,-11.15px_-10.39px_48px_-12px_#00000026] backdrop-blur-[4.16px] backdrop-brightness-[100%] [-webkit-backdrop-filter:blur(4.16px)_brightness(100%)] before:content-[''] before:absolute before:inset-0 before:p-px before:rounded-[10px] before:[background:conic-gradient(from_90deg_at_100%_100%,rgba(255,255,255,0.36)_12%,rgba(255,255,255,0)_37%,rgba(255,255,255,0.36)_62%,rgba(255,255,255,0)_87%)] before:[-webkit-mask:linear-gradient(#fff_0_0)_content-box,linear-gradient(#fff_0_0)] before:[-webkit-mask-composite:xor] before:[mask-composite:exclude] before:z-[1] before:pointer-events-none">
      <div className="absolute top-[409px] left-0 w-[1387px] h-[74px] bg-[#3a3f4a]" />

      <div className="absolute top-[417px] left-[1015px] w-[211px] h-[58px] overflow-hidden">
        <button
          className="absolute top-px left-px w-[210px] h-[57px] bg-[#162c5e80] rounded-[22px] border-none cursor-pointer"
          aria-label="Topup"
        >
          <span className="absolute top-0 left-[66px] w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-4xl tracking-[0] leading-[normal] whitespace-nowrap">
            Topup
          </span>
          <img
            className="absolute w-0 h-[41.38%] top-[33.19%] left-[15.76%]"
            alt=""
            src={path}
          />
          <img
            className="absolute w-[16.59%] h-[39.66%] top-[14.22%] left-[7.23%]"
            alt=""
            src={path2}
          />
        </button>
      </div>

      <header className="inline-flex flex-col items-start gap-[5px] absolute top-5 left-[22px]">
        <h2 className="relative w-[421px] h-[53px] mt-[-1.00px] [font-family:'Poppins-Medium',Helvetica] font-medium text-[#a6a6a6] text-5xl tracking-[0] leading-[normal] whitespace-nowrap">
          Total balance
        </h2>
        <p className="relative w-[429px] h-[72px] [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-5xl tracking-[0] leading-[normal]">
          $13450.00
        </p>
      </header>

      <img
        className="absolute w-[2.16%] h-[8.04%] top-[87.84%] left-[15.84%]"
        alt=""
        src={vector5}
      />

      <address className="absolute top-[448px] left-[22px] w-[156px] [font-family:'Poppins-Regular',Helvetica] font-normal text-[#878c98] text-sm tracking-[0] leading-[normal] not-italic">
        0xF09...67c445fg84
      </address>

      <div className="absolute w-48 h-[291px] top-[149px] left-[22px] flex">
        <div className="w-[202px] h-[291px] relative">
          <p className="absolute top-[273px] left-0 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base tracking-[0] leading-[normal] whitespace-nowrap">
            Your address
          </p>
          <p className="absolute top-[273px] left-0 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base tracking-[0] leading-[normal] whitespace-nowrap">
            Your address
          </p>
          <p className="absolute top-0 left-0 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base tracking-[0] leading-[normal] whitespace-nowrap">
            За всё время +500%
          </p>
          <p className="absolute top-0 left-0 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base tracking-[0] leading-[normal] whitespace-nowrap">
            За всё время +500%
          </p>
          <p className="absolute top-0 left-0 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base tracking-[0] leading-[normal] whitespace-nowrap">
            За всё время +500%
          </p>
        </div>
      </div>

      <div className="absolute top-[408px] left-[270px] w-px h-[77px] bg-[#13131366] rounded-[5px]" />

      <div className="absolute top-[47px] left-[407px] w-[923px] h-[341px] bg-[#162c5e80] rounded-[22px]" />

      <div
        className="absolute top-[51px] left-[393px] w-[923px] h-[341px] flex overflow-hidden"
        data-highcharts-core-mode="light"
        role="img"
        aria-label="Balance chart showing growth over 12 months"
      >
        <div className="w-[923px] h-[341px] relative overflow-hidden bg-[url(/vector-6.svg)] bg-[100%_100%]">
          <img
            className="absolute w-[88.41%] h-[81.52%] top-[-11.44%] left-[-445.29%]"
            alt=""
            src={vector7}
          />
          <img
            className="absolute w-[88.41%] h-[81.52%] top-[4.40%] left-[8.94%]"
            alt=""
            src={group}
          />
          <div className="absolute w-[88.41%] h-[81.52%] top-[4.55%] left-[8.88%]">
            <img
              className="absolute w-full h-0 top-[99.82%] left-0 object-cover"
              alt=""
              src={vector8}
            />
            <img
              className="absolute w-full h-0 top-[79.68%] left-0 object-cover"
              alt=""
              src={vector9}
            />
            <img
              className="absolute w-full h-0 top-[59.53%] left-0 object-cover"
              alt=""
              src={vector10}
            />
            <img
              className="absolute w-full h-0 top-[39.75%] left-0 object-cover"
              alt=""
              src={vector11}
            />
            <img
              className="absolute w-full h-0 top-[19.60%] left-0 object-cover"
              alt=""
              src={vector12}
            />
            <img
              className="absolute w-full h-0 top-0 left-0 object-cover"
              alt=""
              src={vector13}
            />
          </div>
          <img
            className="absolute w-[88.41%] h-[81.52%] top-[-11.29%] left-[-445.23%]"
            alt=""
            src={vector14}
          />
          <div className="absolute w-[88.41%] h-0 top-[86.07%] left-[8.88%] bg-[url(/vector-15.svg)] bg-cover bg-[50%_50%]" />
          <div className="absolute w-0 h-[81.52%] top-[4.40%] left-[8.88%] bg-[url(/vector-16.svg)] bg-[100%_100%]" />
          <img
            className="absolute w-[816px] h-[278px] top-[15px] left-[82px]"
            alt=""
            src={image}
          />
          <div className="w-0 h-[6.74%] top-[3.17%] left-[50.05%] [font-family:'Inter-Regular',Helvetica] font-normal text-highcharts-core-vikafjell-colors-general-labels text-[19.2px] text-center whitespace-nowrap absolute tracking-[0] leading-[normal]">
            {""}
          </div>
          <div className="w-0 h-[4.40%] top-[4.75%] left-[50.05%] [font-family:'Inter-Regular',Helvetica] font-normal text-highcharts-core-vikafjell-colors-general-axistitles text-[12.8px] text-center whitespace-nowrap absolute tracking-[0] leading-[normal]">
            {""}
          </div>
          <div className="w-0 h-[4.40%] top-[96.48%] left-[2.71%] [font-family:'Inter-Regular',Helvetica] font-normal text-highcharts-core-vikafjell-colors-general-labels text-xs absolute tracking-[0] leading-[normal]">
            {""}
          </div>
          <div className="absolute w-[86.13%] h-[4.40%] top-[90.09%] left-[11.38%]">
            {months.map((month, index) => {
              const positions = [
                "0",
                "8.49%",
                "16.98%",
                "25.66%",
                "33.96%",
                "42.77%",
                "51.57%",
                "59.75%",
                "68.30%",
                "76.98%",
                "85.35%",
                "93.96%",
              ];
              const widths = [
                "2.77%",
                "2.89%",
                "3.02%",
                "2.77%",
                "3.27%",
                "2.77%",
                "2.26%",
                "3.02%",
                "3.02%",
                "2.77%",
                "3.14%",
                "3.02%",
              ];
              return (
                <div
                  key={month}
                  className={`absolute h-full top-0 [font-family:'Inter-Regular',Helvetica] font-normal text-[#24e0f9] text-[12.8px] text-center tracking-[0] leading-[normal] whitespace-nowrap`}
                  style={{ width: widths[index], left: positions[index] }}
                >
                  {month}
                </div>
              );
            })}
          </div>
          <div className="absolute w-[5.53%] h-[85.92%] top-0 left-[3.03%]">
            {yAxisLabels.map((label, index) => {
              const positions = [
                "94.88%",
                "75.77%",
                "57.00%",
                "37.88%",
                "19.11%",
                "0",
              ];
              const widths = [
                "15.69%",
                "62.75%",
                "62.75%",
                "74.51%",
                "76.47%",
                "72.55%",
              ];
              const leftPositions = [
                "60.78%",
                "13.73%",
                "13.73%",
                "0",
                "0",
                "3.92%",
              ];
              return (
                <div
                  key={label}
                  className={`absolute h-[5.12%] [font-family:'Inter-Regular',Helvetica] font-normal text-[#20dff9] text-[12.8px] text-right tracking-[0] leading-[normal] whitespace-nowrap`}
                  style={{
                    width: widths[index],
                    top: positions[index],
                    left: leftPositions[index],
                  }}
                >
                  {label}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <aside className="absolute top-[186px] left-3.5 w-[366px] h-52">
        <div className="absolute top-0 left-px w-[365px] h-52 bg-[#162c5e80] rounded-[22px]" />
        <h3 className="top-1 left-24 w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-base whitespace-nowrap absolute tracking-[0] leading-[normal]">
          Последние действия:
        </h3>
        {recentActivities.map((activity, index) => {
          const topPositions = ["42px", "73px", "107px", "141px"];
          return (
            <p
              key={index}
              className={`absolute left-[9px] w-[350px] [font-family:'Poppins-SemiBold',Helvetica] text-white text-base tracking-[0] leading-[normal] whitespace-nowrap`}
              style={{ top: topPositions[index] }}
            >
              {activity.address ? (
                <>
                  <span className="font-semibold">{activity.text}</span>
                  <span className="[font-family:'Poppins-Regular',Helvetica] font-normal">
                    {activity.address}
                  </span>
                  <span className="font-semibold">{activity.date}</span>
                </>
              ) : (
                <span className="font-semibold">{activity.text}</span>
              )}
            </p>
          );
        })}
        <div className="absolute w-[99.73%] h-[65.65%] top-[17.31%] left-0">
          <img
            className="absolute w-full h-0 top-[99.63%] left-0 object-cover"
            alt=""
            src={vector17}
          />
          <img
            className="absolute w-full h-0 top-[74.41%] left-0 object-cover"
            alt=""
            src={vector18}
          />
          <img
            className="absolute w-full h-0 top-[49.63%] left-0 object-cover"
            alt=""
            src={vector19}
          />
          <img
            className="absolute w-full h-0 top-[24.41%] left-0 object-cover"
            alt=""
            src={vector20}
          />
          <img
            className="absolute w-full h-0 top-0 left-0 object-cover"
            alt=""
            src={vector21}
          />
        </div>
      </aside>

      <div className="absolute top-[418px] left-[316px] w-[211px] h-[58px] overflow-hidden">
        <button
          className="absolute top-px left-px w-[210px] h-[57px] bg-[#162c5e80] rounded-[22px] border-none cursor-pointer"
          aria-label="Send"
        >
          <img
            className="absolute w-[16.59%] h-[25.86%] top-[17.67%] left-[8.18%]"
            alt=""
            src={path3}
          />
          <img
            className="absolute w-0 h-[60.34%] top-[17.67%] left-[16.47%]"
            alt=""
            src={path4}
          />
          <span className="absolute top-0.5 left-[77px] w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-4xl tracking-[0] leading-[normal] whitespace-nowrap">
            SEND
          </span>
        </button>
      </div>

      <div className="absolute top-[417px] left-[547px] w-[211px] h-[58px] overflow-hidden">
        <button
          className="absolute top-[3px] left-0 w-[210px] h-[57px] bg-[#162c5e80] rounded-[22px] border-none cursor-pointer"
          aria-label="Receive"
        >
          <img
            className="absolute w-0 h-[60.34%] top-[21.12%] left-[16.94%]"
            alt=""
            src={path5}
          />
          <img
            className="absolute w-[16.59%] h-[25.86%] top-[55.60%] left-[8.65%]"
            alt=""
            src={path6}
          />
          <span className="absolute top-[3px] left-[62px] w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-4xl tracking-[0] leading-[normal] whitespace-nowrap">
            Receive
          </span>
        </button>
      </div>

      <div className="absolute top-[417px] left-[781px] w-[211px] h-[58px] overflow-hidden">
        <button
          className="absolute top-px left-px w-[210px] h-[57px] bg-[#162c5e80] rounded-[22px] border-none cursor-pointer"
          aria-label="Loan"
        >
          <span className="absolute top-0.5 left-[79px] w-48 [font-family:'Poppins-SemiBold',Helvetica] font-semibold text-white text-4xl tracking-[0] leading-[normal] whitespace-nowrap">
            loan
          </span>
          <img
            className="absolute w-[4.27%] h-[22.41%] top-[36.72%] left-[13.89%]"
            alt=""
            src={path7}
          />
          <div className="absolute top-[11px] left-[17px] w-[35px] h-[35px] rounded-3xl border-[1.5px] border-solid border-ffffff" />
        </button>
      </div>
    </section>
  );
};
