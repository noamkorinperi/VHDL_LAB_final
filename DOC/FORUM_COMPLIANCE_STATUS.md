# סטטוס התאמה לשאלות ותשובות הפורום

עודכן: 27.08.2026 IDT

## שער שחרור

**הענף הזה טרם עבר אימות פיזי על DE10-Standard.** הוא עבר סימולציה,
סינתזה ותזמון בלבד. האימות הפיזי המתועד ב־`main` בוצע לפני השינויים האלה
ואינו מהווה הוכחה עבור הענף החדש.

## התאמות שבוצעו

| נושא מהפורום | מצב בענף |
|---|---|
| שלושה שעונים מ־PLL נפרדים | שלושה מופעים לוגיים: MCLK=20MHz, SMCLK=20MHz, DIVCLK=50MHz; reset מחכה לכל ה־locks. Quartus משתף פיזית את שני מופעי ה־20MHz הזהים. |
| DATA BUS משותף ודו־כיווני | CPU, DTCM, MMIO ו־TYPE נוהגים על bus אחד; כל מי שאינו בעלים מוציא `Z`. |
| TYPE בזמן INTA | TYPE נהוג על DATA BUS בזמן INTA ולא על address bus. |
| KEY1–KEY3 | מיפוי bit0/1/2 נשמר; אין debounce או synchronizer נוסף; אירוע יחיד בשחרור 0→1. |
| IFG ו־IE | אירוע מגדיר IFG רק אם IE פעיל; ביטול IE מנקה IFG ולא נשמר אירוע מוסווה. |
| BTCAPR | רגיסטר 32-bit לקריאה וכתיבה. |
| BTCTL2 | ארבעת הביטים העליונים נשארים read-only; כתיבה משפיעה רק על הנמוכים. |
| HEX זוגי/אי־זוגי | בחירת HEX0/1, HEX2/3 ו־HEX4/5 נעשית במפורש בעזרת A0. |
| פסיקה באמצע DIV | בדיקה ייעודית מוכיחה ש־DIV מסתיים ונכתב חזרה לפני INTA, ולאחר ISR הזרימה ממשיכה. |
| CDC של המחלק | request/ack toggle, שני DFF ביעד בכל כיוון, ו־payload יציב לאורך ה־handshake. |

## תוצאות אוטומטיות

- ModelSim: כל תשעת יישומי הייחוס עברו (`9/9`).
- ModelSim: בדיקות interconnect/GPIO/timer/pushbuttons/interrupt controller עברו.
- ModelSim: `STAGE 7 DIVIDER/INTERRUPT ORDER PASS`.
- Quartus Prime Lite 21.1 Full Compilation: `0 errors`.
- Synthesis: נמצאו שלושה מופעי PLL לוגיים.
- Fitter: `2,080 ALMs`, ‏`2,029 registers`, ‏`4 DSP blocks`.
- TimeQuest: fully constrained, `0 errors`, `0 warnings`, ‏TNS=`0`.
- Worst setup slack: `+0.474 ns`; worst hold slack: `+0.160 ns`.

## אימות פיזי שנותר

נוהל הבדיקה המלא, כולל build, צריבה, תוצאות צפויות ותבנית ראיות, נמצא
ב־[`חשוב_הוראות_אימות_פיזי_על_הכרטיס.md`](../חשוב_הוראות_אימות_פיזי_על_הכרטיס.md)
בשורש המאגר.

יש לצרוב את ה־SOF שנבנה מהענף ולחזור על ארבעת תרחישי המעבדה:

1. KEY0/reset ואתחול HEX/מצב.
2. KEY1/compare interrupts וקצבי הספירה.
3. KEY2/PWM ו־LEDR8.
4. KEY3/REM ו־DIV, כולל חזרה תקינה לפעילות לאחר כל ISR.

רק לאחר שכל ארבע הבדיקות יעברו ניתן להסיר את אזהרת "לא אומת פיזית".
