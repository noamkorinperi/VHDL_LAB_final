# בדיקות ModelSim — שלבים 0 עד 3

הבדיקות מוכנות להרצה נפרדת. הן לא הורצו ביום ההכנה, בהתאם להחלטה לדחות את
ModelSim. כל script יוצר מחדש את ספריית `work`, מקמפל רק את הקבצים הדרושים,
פותח Wave מתאים, מריץ עד לסיום וכותב log בתיקיית `SIM/RV32IMscMCU`.

## הכנה חד-פעמית

1. לפתוח ModelSim Intel FPGA Starter Edition.
2. לבחור `File > Change Directory` ולעבור אל:
   `C:/Users/noam1/Desktop/VHDL Lab/Final proj/SIM/RV32IMscMCU`
3. לוודא שבחלון Transcript מופיע הנתיב הזה.
4. אין צורך ליצור project גרפי ב-ModelSim; קובצי ה-`.do` עושים זאת בעצמם.

## סדר ההרצה

### 1. שלב 0 — baseline

ב-Transcript:

```tcl
do run_stage0_baseline.do
```

תוצאה תקינה: מופיעה ההודעה
`STAGE 0 PASS: RV32I/MUL baseline and DTCM regression`, ללא `Failure` או
`Error`. ה-TB בודק שה-benchmark מגיע ללולאת העצירה, שיש פעולות `MUL`,
שהתוצאה תואמת למכפלת 16 הביטים התחתונים ושיש כתיבות DTCM.

### 2. שלב 1 — Address decoder ו-read mux

```tcl
do run_stage1_interconnect.do
```

תוצאה תקינה: `STAGE 1 INTERCONNECT PASS`. הבדיקה מכסה המרת byte address
ל-word index ב-DTCM, שמירת כל ביטי הכתובת ב-MMIO, הפרדה בין write-enables,
read mux וגישה לכתובת שאינה ממומשת.

### 3. שלב 2 — GPIO unit test

```tcl
do run_stage2_gpio_unit.do
```

תוצאה תקינה: `STAGE 2 GPIO UNIT PASS`. הבדיקה מכסה reset, כתיבת low byte
ל-LEDR, הכתובות הצמודות והלא מיושרות של HEX, קידוד active-low, קריאת
switches עם zero extension, ודחיית כתובת שאינה ממומשת.

### 4. שלב 2 — GPIO integration

```tcl
do run_stage2_gpio_integration.do
```

תוצאה תקינה: `STAGE 2 GPIO INTEGRATION PASS`. ה-TB מריץ את
`Benchmark apps/GPIO/test0`, דורש לפחות שתי כתיבות ל-LEDR ושתי סדרות של
כתיבות לכל ששת ה-HEX, ומוודא שבסוף הסדרה השנייה `LEDR=0x01`.

בדיקה זו נשענת על `test0`, שאין בו תלות בגירוי switches ולכן הוא
דטרמיניסטי. שני ה-benchmarks הנוספים נבדקים אוטומטית בסעיף הבא.

### 5. שלב 2 — benchmarks עם switches

```tcl
do run_stage2_gpio_switch_benchmarks.do
```

תוצאה תקינה: `STAGE 2 GPIO TEST1/TEST2 INTEGRATION PASS`. ה-TB מריץ במקביל
את `GPIO/test1` ואת `GPIO/test2`, מפעיל את SW0, ודורש מכל תוכנה כתיבה של
הערך 1 ל-LEDR וכתיבה לכל ששת צגי ה-HEX.

### 6. שלב 3 — Divider unit test

```tcl
do run_stage3_divider_unit.do
```

תוצאה תקינה: `STAGE 3 DIVIDER UNIT PASS`. נבדקים `DIV`, `DIVU`, `REM`,
`REMU`, סימנים, חלוקה באפס ו-overflow של `0x80000000 / -1`. צריך לראות
בקירוב 32 מחזורי `divclk` לפעולה רגילה; מקרי קצה מסתיימים מוקדם יותר.

### 7. שלב 3 — שילוב CPU/Divider

```tcl
do run_stage3_divider_integration.do
```

תוצאה תקינה: `STAGE 3 CPU/DIVIDER INTEGRATION PASS`. ה-TB מריץ את
benchmark ה-RV32IM הידני, סופר בדיוק שמונה `DIV` ושמונה `REM`, מוודא שה-PC
נשאר קבוע בזמן `busy`, שאין write-back מוקדם, ושיש write-back יחיד ב-`done`.

## מה לשמור אחרי כל בדיקה

- צילום Wave שמראה את האותות המרכזיים ואת הודעת ה-PASS.
- קובץ ה-log שנוצר אוטומטית: `stage0_baseline.log`, `stage1_interconnect.log`,
  `stage2_gpio_unit.log`, `stage2_gpio_integration.log`,
  `stage2_gpio_switch_benchmarks.log`,
  `stage3_divider_unit.log`, או `stage3_divider_integration.log`.
- אם יש כשל, לא להמשיך לבדיקה הבאה: לשמור את ה-log וה-Wave ולרשום באיזה
  script ובאיזו הודעת assertion נעצרה הריצה.

## הערה על ספריות Intel

בדיקות ה-CPU משתמשות ב-`altsyncram`, ולכן scripts אלה מפעילים
`vsim -L altera_mf`. אם ModelSim אינו מוצא את הספרייה, יש להריץ פעם אחת
`Tools > Compile Simulation Libraries` עבור Cyclone V/ModelSim Intel FPGA,
ואז לחזור על ה-script. בדיקות ה-GPIO וה-divider העצמאיות אינן תלויות ב-IP.
