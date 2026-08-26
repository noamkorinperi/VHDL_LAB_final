# שלב 9 — Quartus ו־DE10-Standard

עודכן: 26.08.2026

## מצב build

- Quartus Prime Lite 21.1, רכיב `5CSXFC6D6F31C6`, top-level `RV32IMscMCU`.
- Full Compilation הסתיים בהצלחה: 0 errors.
- Analysis & Synthesis: 0 errors; Fitter: 0 errors; Assembler: 0 errors.
- TimeQuest לאחר תיקון ה־CDC constraints: 0 errors, 0 warnings.
- worst setup slack: `+2.664 ns`; worst hold slack: `+0.143 ns` בכל הפינות המסוכמות.
- SOF סופי: `Quartus/RV32IMscMCU/output_files/RV32IMscMCU.sof`.

## ניצול משאבים

| משאב | שימוש |
|---|---:|
| ALMs | 2,010 / 41,910 (5%) |
| Registers | 2,033 |
| Pins | 67 / 499 (13%) |
| Block memory | 131,072 bits (2%), 14 blocks |
| DSP | 4 / 112 (4%) |
| PLL | 1 / 15 (7%) |

כל 67 ה־I/O pins ממופים. אזהרת ה־Fitter לגבי I/O מתייחסת רק לכך שלא הוגדרו drive-strength ו־slew-rate מפורשים ל־LEDR/HEX; Quartus משתמש בברירות המחדל של `3.3-V LVTTL`. אזהרת עומק ה־DTCM צפויה: תמונת הקושחה מכילה 1024 מילים בתוך RAM של 2048 מילים, והחצי העליון מאותחל לאפס.

## קושחת ההדגמה

ה־SOF משתמש ב־`interrupt/test4` של המדריך:

- `KEY0` — reset פעיל־נמוך.
- `KEY1` — הפעלת compare interrupt ושינוי מחזור ההפרעה.
- `KEY2` — הפעלת PWM ושינוי duty cycle; ה־PWM נראה גם ב־`LEDR8`.
- `KEY3` — capture ומדידת זמני מערכי DIV/REM.
- `LEDR9` — חיווי של לחצן debounced פעיל.
- `SW8`, `SW9` — כניסות capture.

## build חוזר

מתוך `Quartus/RV32IMscMCU`:

```text
compile_stage9.cmd
verify_timing_stage9.cmd
```

הסקריפטים ממפים זמנית את שורש ה־workspace לכונן `V:` מפני ש־Quartus 21.1 משמיט את רכיב `Desktop` כאשר הוא מקבל את הנתיב הנוכחי ישירות. המיפוי מוסר בסיום.

## תוצאות הבדיקה על הכרטיס

ב־26.08.2026 ה־SOF נטען דרך `DE-SoC [USB-1]` אל רכיב FPGA מספר 2 בשרשרת
ה־JTAG. האימות הפיזי עבר:

1. `KEY0` איפס את תצוגות ה־HEX ואת מצב הקושחה.
2. `KEY1` הפעיל compare interrupts, הדליק את `LEDR9` בזמן הלחיצה ועדכן את
   הספירה בקצבים המחזוריים 1, ‏0.5, ‏0.25 ו־0.125 שניות.
3. `KEY2` עצר את הספירה והפעיל PWM ב־`LEDR8`.
4. שתי לחיצות `KEY3` השלימו את מדידות REM ו־DIV; לאחר כל רצף `KEY1` חזר
   להפעיל את הספירה ללא קיפאון.

במהלך האימות תוקנו שני מעברים בין מצבי הטיימר בקובץ הקושחה הייעודי לכרטיס:
נוסף `BTCLR` בהפעלת PWM ובהפעלה מחדש של compare mode, כדי למנוע מצב שבו
`BTCNT` כבר עבר את ערך ההשוואה החדש. רגרסיית ModelSim המלאה עברה 9/9 לאחר
שני התיקונים, וה־SOF הסופי נבנה עם 0 שגיאות.

שער שלב 9 הושלם. שמירת ראיות SignalTap תבוצע בשלב 10.
