# סיכום מוכנות שלב 1

תאריך: 12.08.2026

## תוצאה

שלב 1 מוכן. הוגדרו ארכיטקטורת המערכת, ממשק ה-data bus, מפת הכתובות,
תוכנית clocks/reset, ממשקי divider/interrupts, Top-Level מבני יציב ושלד Quartus
ל-DE10-Standard. Analysis & Synthesis עבר בהצלחה.

חומרי המקור בתיקיות `מעבדה קודמת שלנו`, `קבצים מהמדריך` ו-`Benchmark apps`
לא שונו.

## שער היציאה של שלב 1

- [x] תרשים Top-Level מבני.
- [x] הגדרת CPU כ-bus master יחיד.
- [x] הפרדת DTCM ו-MMIO ושמירת ביטי הכתובת הנמוכים.
- [x] package יחיד עם כל כתובות MMIO וערכי TYPE.
- [x] מפרט clocks, reset ו-CDC.
- [x] מפרט `INTR/INTA/TYPE` וכניסה דו-מחזורית לפסיקה.
- [x] Top-Level בשם `RV32IMscMCU`.
- [x] פרויקט Quartus עבור Cyclone V `5CSXFC6D6F31C6`.
- [x] Quartus Analysis & Synthesis ללא errors.
- [x] כתובות ה-package הושוו לקובצי `io_map.s` של ה-benchmarks.

## תוצרי השלב

- `DOC/ARCHITECTURE.md` - מפרט הארכיטקטורה המלא.
- `DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd` - מקור האמת לכתובות.
- `DUT/RV32IMscMCU/RV32IMscMCU.vhd` - Top-Level מבני ראשוני.
- `DUT/RV32IMscMCU/COMPILE_ORDER.txt` - סדר קומפילציה.
- `Quartus/RV32IMscMCU/RV32IMscMCU.qpf` - פרויקט Quartus.
- `Quartus/RV32IMscMCU/RV32IMscMCU.qsf` - device וקובצי המקור.
- `Quartus/RV32IMscMCU/RV32IMscMCU.sdc` - אילוץ `CLOCK_50` של 20ns.
- `Quartus/RV32IMscMCU/output_files/RV32IMscMCU.map.rpt` - דוח synthesis.

## תוצאת Quartus

כלי: Quartus Prime Lite 21.1.0 Build 842.

- Analysis & Synthesis: success.
- Errors: 0.
- Warnings: 60.
- Registers after synthesis: 1,271.
- Block-memory bits: 131,072.
- DSP blocks: 4.

ה-warnings שנבדקו בשלב זה צפויים:

1. קובצי ITCM/DTCM קצרים מעומק הזיכרון שהוקצה; Quartus מאתחל את שאר
   הכתובות לאפס.
2. `SW` ו-KEY1-KEY3 עדיין אינם בשימוש כי GPIO ו-pushbuttons מתחילים בשלבים
   2 ו-5.
3. HEX0-HEX5 מוחזקים כבויים עד מימוש GPIO בשלב 2.
4. `SBtype_w` הוא אות לא-בשימוש בקוד ה-control שהועתק מהמעבדה.

אין ב-warnings הנוכחיים כשל elaboration, בעיית device או שגיאת VHDL.

## מצב שלב 0

עבודת ההכנה שאינה תלויה ב-ModelSim הושלמה: עץ עבודה נקי, מקורות single-cycle,
נתיבי זיכרון ניידים, קובצי HEX מקומיים וסדר קומפילציה.

המשימות הבאות נדחו במפורש ליום ModelSim:

- קומפילציית testbench.
- הרצת RV32IM baseline.
- השוואת DTCM מול RARS.
- שמירת log ו-waveform של baseline.

לכן שלב 0 מסומן כחוב אימות ולא ככשל. שלב 2 עדיין לא התחיל.
