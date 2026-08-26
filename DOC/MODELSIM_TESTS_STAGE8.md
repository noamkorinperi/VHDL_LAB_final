# שלב 8 — אינטגרציה ואימות מלא ב־ModelSim

עודכן: 25.08.2026

## הרצה

מתוך `SIM/RV32IMscMCU`:

```text
vsim -c -do "do run_stage8_full_verification.do; quit -f"
```

הסקריפט מקמפל את כל מקורות ה־MCU, מריץ testbench מרכזי ובודק־עצמית ושומר
transcript ב־`stage8_full_verification.log`. קובץ
`stage8_representative_wave.do` משחזר את קבוצת הגלים המייצגת של test4.

## כיסוי ה־benchmarks

| ID | יישום | תוצאה |
|---:|---|---|
| 0 | RV32IM test1, manual | PASS |
| 1 | RV32IM test1, GCC | PASS |
| 2 | GPIO test0 | PASS |
| 3 | GPIO test1 | PASS |
| 4 | GPIO test2 | PASS |
| 5 | Interrupt test1 | PASS |
| 6 | Interrupt test2 | PASS |
| 7 | Interrupt test3 | PASS |
| 8 | Interrupt test4 | PASS |

שורת הסיום המאומתת היא `STAGE 8 FULL VERIFICATION PASS`.

## בדיקות אוטומטיות

- השוואה מילה־במילה של 24 תוצאות RV32IM בכתובות `0x40..0x9C` מול פלט RARS שסופק.
- אימות writes ל־GPIO, HEX, timer compare/capture, מערכי DIV/REM ותוצאות runtime.
- גירוי switches, שלושת pushbuttons, שני capture inputs ושני דומייני השעון.
- assertions עבור X/U לאחר reset, read/write חופפים, חפיפת DTCM/MMIO, כתיבה בזמן divider busy, timeout, חזרת ISR וניקוי IFG.
- test4 מאמת תכנות CMP0/CMP1, עליית PWM ופולס יציב. ירידת הפולס אינה מדומה עד סוף מחזור של 20,000,000 clocks, כדי לשמור על regression מעשי.

## מדדי ביצועים

`effective-retire-cycles` סופר מחזורים שבהם הליבה אינה ב־divider stall ואינה בתוך FSM הפסיקה. המדד המדווח הוא:

```text
IPC = effective-retire-cycles / total-cycles
```

| benchmark | cycles | effective-retire-cycles | IPC |
|---|---:|---:|---:|
| RV32IM manual | 508 | 188 | 0.370 |
| RV32IM GCC | 890 | 570 | 0.640 |

זהו מדד utilization של ליבת single-cycle, ולא מונה retirement ארכיטקטוני נפרד.

## התאמות שנדרשו לאחר עדכון המדריך

- טבלת הווקטורים החדשה מעורבת: tests 1–3 מכילים כתובות ITCM מקומיות, בעוד test4 עדיין מכיל כתובות מקושרות מבסיס `0x3000`. הליבה מנרמלת כעת את שני הפורמטים.
- תוכנית GCC משתמשת במחסנית ללא startup שמאתחל `sp`; בנק האוגרים מאתחל כעת את `x2` לראש ה־DTCM (`0x2000`).
- ב־interrupt/test1 פקודת הקפיצה של מצב ModelSim עוקפת את EINT. נשמר עותק מתוקן בן מילה אחת תחת `SIM/RV32IMscMCU/firmware`; תיקיית המדריך אינה משתנה.

לאחר התיקונים הורצו מחדש כל סקריפטי שלבים 0–7, וכולם עברו.
