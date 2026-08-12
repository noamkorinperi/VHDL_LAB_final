# תוכנית עבודה למחר — אימות ModelSim של שלבים 0–3

נוצר: 12.08.2026 21:58 IDT  
פרויקט: RV32IM single-cycle MCU עבור DE10-Standard

מטרת יום הבדיקה היא להריץ שבע בדיקות אוטומטיות, לפי הסדר, ולסגור רשמית
את שערי היציאה של שלבים 0–3. אין לבצע מחר בדיקת FPGA ואין לשנות קוד לפני
שמירת פרטי הכשל הראשון, אם יהיה כשל.

## 1. מה צריך להיות זמין

- מחשב עם ModelSim Intel FPGA Starter Edition.
- תיקיית הפרויקט המלאה בנתיב:
  `C:/Users/noam1/Desktop/VHDL Lab/Final proj`
- הקבצים `run_stage0_baseline.do` עד `run_stage3_divider_integration.do`
  בתיקייה `SIM/RV32IMscMCU`.
- מקום לשמור שבעה צילומי מסך ושבעת קובצי ה-log.
- אין צורך בכרטיס DE10-Standard במהלך הבדיקות האלה.
- אין צורך ליצור ModelSim Project גרפי; קובצי ה-`.do` מטפלים בספריית
  `work`, בקומפילציה, בפתיחת ה-Wave ובהרצה.

## 2. כללי עבודה חשובים

1. מריצים את הבדיקות לפי הסדר המופיע במסמך.
2. מריצים בכל פעם script אחד בלבד וממתינים לסיום.
3. הצלחה נקבעת רק לפי הודעת ה-PASS המדויקת ב-Transcript.
4. הודעת `Simulation stop requested` אחרי PASS היא תקינה: ה-testbench
   קורא ל-`std.env.stop` בסיום מוצלח.
5. אם מופיעים `Error`, ‏`Failure`, ‏`Fatal` או שאין PASS — הבדיקה נכשלה.
6. בכשל הראשון עוצרים. לא ממשיכים לבדיקה הבאה ולא מריצים מחדש לפני
   ששומרים את ה-log וה-Wave, כי הרצה חוזרת עשויה לדרוס את ה-log.
7. אין לערוך קובצי DUT, ‏TB, ‏`.do` או `.hex` בזמן יום הבדיקה.

## 3. פתיחת סביבת העבודה

1. פתח ModelSim Intel FPGA Starter Edition.
2. בחר `File > Change Directory`.
3. עבור אל:

   ```text
   C:/Users/noam1/Desktop/VHDL Lab/Final proj/SIM/RV32IMscMCU
   ```

4. ודא שהנתיב הנוכחי ב-Transcript הוא התיקייה הזאת. אפשר להקליד:

   ```tcl
   pwd
   ```

5. ודא שבתיקייה מופיעים שבעת קובצי ה-`.do` ושקובצי `ITCM.hex` ו-`DTCM.hex`
   קיימים.

## 4. אם ModelSim אינו מוצא את ספריית Intel

חלק מבדיקות ה-CPU משתמשות ב-`altsyncram` ומפעילות את ModelSim עם
`-L altera_mf`. אם מתקבלת שגיאה כגון `Library altera_mf not found` או
שגיאה על `altsyncram`:

1. עצור את ההרצה.
2. בחר `Tools > Compile Simulation Libraries`.
3. בחר את ModelSim Intel FPGA ואת משפחת Cyclone V.
4. קמפל את ספריות הסימולציה.
5. חזור לתיקיית העבודה והריץ שוב את אותה בדיקה.

זו בעיית הגדרת כלי, לא כשל לוגי של הפרויקט. אם הקומפילציה של הספריות
נכשלת, שמור צילום ואת טקסט השגיאה ושלח אותם לפני המשך העבודה.

## 5. הבדיקות לפי הסדר

### בדיקה 1 — שלב 0: RV32I/MUL baseline ו-DTCM

- [ ] הרץ ב-Transcript:

  ```tcl
  do run_stage0_baseline.do
  ```

- [ ] ודא שמופיעה ההודעה:

  ```text
  STAGE 0 PASS: RV32I/MUL baseline and DTCM regression
  ```

- [ ] ב-Wave ודא שקיימים `sysclk`, ‏`divclk`, ‏`reset`, ‏`pc`,
  `instruction`, ‏`r1`, ‏`r2`, ‏`alu`, ‏`regwrite` ו-`memwrite`.
- [ ] שמור צילום שבו רואים את ה-Wave ואת הודעת ה-PASS.
- [ ] ודא שנוצר `stage0_baseline.log`.

מה ה-TB מוכיח: ה-benchmark מגיע ללולאת העצירה לפני timeout, נצפית לפחות
פקודת `MUL` אחת, תוצאת הכפל תואמת למכפלת 16 הביטים התחתונים, ונצפית לפחות
כתיבה אחת ל-DTCM.

### בדיקה 2 — שלב 1: Address decoder ו-read mux

- [ ] הרץ:

  ```tcl
  do run_stage1_interconnect.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 1 INTERCONNECT PASS
  ```

- [ ] ב-Wave ודא שהאותות מוצגים ב-hex ושניתן לראות מעבר בין DTCM, ‏MMIO
  וכתובת שאינה ממומשת.
- [ ] שמור צילום ואת `stage1_interconnect.log`.

מה ה-TB מוכיח: byte address מומר נכון ל-word index של DTCM; כתובת MMIO
המלאה נשמרת; write-enable של DTCM ושל MMIO אינם פעילים יחד; ה-read mux
מחזיר את המקור הנכון; גישה לא ממומשת מסומנת ואינה פוגעת בזיכרון.

### בדיקה 3 — שלב 2: GPIO unit test

- [ ] הרץ:

  ```tcl
  do run_stage2_gpio_unit.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 2 GPIO UNIT PASS
  ```

- [ ] ב-Wave בדוק reset, כתיבה ל-LEDR, כתובות HEX, יציאות HEX active-low,
  קריאת switches והאות `hit`.
- [ ] שמור צילום ואת `stage2_gpio_unit.log`.

מה ה-TB מוכיח: reset מנקה LEDR; כתיבת low byte עובדת; הכתובות הצמודות
והלא מיושרות של HEX נשמרות; הקידוד עבור A/F תקין; קריאת SW עוברת zero
extension; כתובת שאינה ממומשת אינה נתפסת בטעות על ידי GPIO.

### בדיקה 4 — שלב 2: GPIO integration עם test0

- [ ] הרץ:

  ```tcl
  do run_stage2_gpio_integration.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 2 GPIO INTEGRATION PASS
  ```

- [ ] ב-Wave אתר כתיבות bus ל-LEDR ולששת ה-HEX.
- [ ] ודא שבסיום `LEDR=0x01`.
- [ ] שמור צילום ואת `stage2_gpio_integration.log`.

מה ה-TB מוכיח: benchmark `GPIO/test0` מבצע לפחות שתי כתיבות ל-LEDR,
שתי סדרות מלאות של כתיבות לששת צגי HEX, ומשאיר LEDR בערך הצפוי.

### בדיקה 5 — שלב 2: GPIO test1/test2 עם SW0

- [ ] הרץ:

  ```tcl
  do run_stage2_gpio_switch_benchmarks.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 2 GPIO TEST1/TEST2 INTEGRATION PASS
  ```

- [ ] ב-Wave ודא ש-`switches` משתנה כך ש-SW0 פעיל.
- [ ] ודא ששני מופעי ה-benchmark כותבים `1` ל-LEDR וכותבים לכל ששת ה-HEX.
- [ ] שמור צילום ואת `stage2_gpio_switch_benchmarks.log`.

מה ה-TB מוכיח: גם `GPIO/test1` וגם `GPIO/test2` קוראים את SW0 ומגיבים אליו
נכון, ללא החלפה ידנית של קובצי הזיכרון.

### בדיקה 6 — שלב 3: Divider unit test

- [ ] הרץ:

  ```tcl
  do run_stage3_divider_unit.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 3 DIVIDER UNIT PASS
  ```

- [ ] ב-Wave בדוק את הרצף `start` → `busy` → `done` ואת `operation`,
  `dividend`, ‏`divisor` ו-`result`.
- [ ] בפעולה רגילה אמורים להיראות בקירוב 32 מחזורי `divclk`; חלוקה באפס
  ו-overflow יכולים להסתיים מוקדם יותר.
- [ ] שמור צילום ואת `stage3_divider_unit.log`.

מה ה-TB מוכיח: `DIV`, ‏`DIVU`, ‏`REM`, ‏`REMU`, ערכים חיוביים ושליליים,
חלוקה באפס ו-`0x80000000 / -1` מחזירים את התוצאה הצפויה.

### בדיקה 7 — שלב 3: שילוב CPU/Divider

- [ ] הרץ:

  ```tcl
  do run_stage3_divider_integration.do
  ```

- [ ] ודא שמופיעה:

  ```text
  STAGE 3 CPU/DIVIDER INTEGRATION PASS
  ```

- [ ] ב-Wave בדוק את `pc`, ‏`instruction`, ‏`div_busy`, ‏`div_done`,
  `regwrite`, ‏`r1`, ‏`r2` ו-`result`.
- [ ] ודא חזותית שה-PC נשאר יציב בזמן `div_busy` וש-`regwrite` עבור תוצאת
  המחלק מתרחש רק עם `div_done`.
- [ ] שמור צילום ואת `stage3_divider_integration.log`.

מה ה-TB מוכיח: ה-benchmark מבצע בדיוק שמונה פעולות DIV ושמונה REM, הליבה
נעצרת בזמן העבודה, אין write-back מוקדם או כפול, וכל תוצאה תואמת לצפוי.

## 6. רשימת קובצי ה-log הצפויים

לאחר שכל הבדיקות עברו, בתיקיית `SIM/RV32IMscMCU` צריכים להופיע:

- [ ] `stage0_baseline.log`
- [ ] `stage1_interconnect.log`
- [ ] `stage2_gpio_unit.log`
- [ ] `stage2_gpio_integration.log`
- [ ] `stage2_gpio_switch_benchmarks.log`
- [ ] `stage3_divider_unit.log`
- [ ] `stage3_divider_integration.log`

## 7. מה לעשות במקרה של כשל

עצור בבדיקה הראשונה שנכשלה ושמור:

1. שם ה-script שהורץ.
2. קובץ ה-log לפני הרצה חוזרת.
3. הטקסט המלא מהשורה הראשונה שמכילה `Error` או `Failure` ועד סוף ההרצה.
4. צילום Wave באזור הזמן שבו הופעל ה-assertion.
5. צילום Transcript הכולל את פקודת `do` ואת הודעת הכשל.
6. האם הכשל היה בזמן compile, בזמן `vsim`, או במהלך `run -all`.

שלח לי את החומרים האלה. לאחר תיקון נריץ שוב את הבדיקה שנכשלה, ורק לאחר
PASS נמשיך לבדיקה הבאה.

## 8. מה לשלוח לאחר שכל הבדיקות עברו

שלח לי הודעה בפורמט הבא:

```text
ModelSim stages 0-3
1. stage0_baseline: PASS
2. stage1_interconnect: PASS
3. stage2_gpio_unit: PASS
4. stage2_gpio_integration: PASS
5. stage2_gpio_switch_benchmarks: PASS
6. stage3_divider_unit: PASS
7. stage3_divider_integration: PASS
Warnings חריגים: אין / פירוט
```

צרף את שבעת קובצי ה-log ואת צילומי ה-Wave. לאחר סקירתם נעדכן את
`PROJECT_PLAN.md` עם זמני הבדיקה, נסמן את שלבים 0–3 כהושלמו, וניצור
checkpoint חדש ב-GitHub. לאחר מכן תתחיל הכנת שלבים 4–5.

## 9. שער סיום יום הבדיקה

יום הבדיקה הושלם רק כאשר מתקיים אחד משני המצבים:

- כל שבע הבדיקות מציגות PASS, וכל שבעת ה-logs וצילומי ה-Wave נשמרו; או
- נעצרנו בכשל הראשון וכל המידע הדרוש לשחזורו נשמר ונשלח.

אין להתחיל שלב 4 על סמך ריצה חלקית של הבדיקות.
