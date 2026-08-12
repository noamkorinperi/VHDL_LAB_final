# סטטוס מימוש שלבים 2–3

## שלב 2 — Memory-Mapped GPIO

המימוש הושלם בקוד:

- ליבת ה-CPU מוציאה data bus מלא של 32 ביט ואינה מחזיקה עוד DTCM פנימי.
- `mcu_interconnect` מפריד בין `0x00000000–0x00001FFF` ל-DTCM לבין
  `0x00002000–0x00003FFF` ל-MMIO. כתובת DTCM נחתכת ל-word address רק
  בכניסה לזיכרון.
- `gpio_peripheral` מממש LEDR7–0, שישה רגיסטרי HEX, encoder active-low
  וקריאת SW7–0. כל קריאה מוחזרת כערך 32 ביט zero-extended.
- כתובות כמו HEX1=`0x2005`, HEX3=`0x2009` ו-HEX5=`0x200D` נשמרות במלואן
  ולכן אינן מתנגשות בכתובת השכנה.
- כתיבת MMIO אינה מפעילה write-enable של DTCM.

## שלב 3 — Divider Accelerator

המימוש הושלם בקוד:

- `divider_unsigned` הוא מחלק restoring של 32 ביט/32 מחזורי DIVCLK.
- `divider_accelerator` מוסיף signed preprocessing/postprocessing ותומך
  ב-`DIV`, `DIVU`, `REM`, `REMU`.
- חלוקה באפס ו-signed overflow ממומשים לפי RV32M.
- toggle handshake עם synchronizers מעביר request/result בין sysclk ל-DIVCLK;
  operand/result buses נשמרים יציבים עד לקבלת acknowledgement.
- IFETCH מקבל `stall_i`; ה-PC מוחזק בזמן הפעולה, וה-register file מקבל
  write-enable רק בפולס `done`.
- ה-top מפיק sysclk של 25 MHz בעזרת PLL ומפעיל את המחלק מ-CLOCK_50 של 50 MHz.

## מצב אימות

- Quartus Analysis & Synthesis עבר בהצלחה עם 0 errors ו-13 warnings.
- תוצאת synthesis: 1,666 registers, ‏131,072 block-memory bits, ‏4 DSP blocks
  ו-PLL אחד. לא נמצאה אזהרת latch, multiple drivers או combinational loop.
- שבע בדיקות ModelSim לשלבים 0–3 מוכנות אך טרם הורצו, לפי בקשת המשתמש. הוראות מפורטות
  נמצאות ב-`DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md`.

שלבים 2 ו-3 נחשבים **מוכנים לבדיקה**, ולא **מאומתים פונקציונלית**, עד שכל
ה-scripts הרלוונטיים מסיימים בהודעת PASS.
