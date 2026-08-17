# בדיקות ModelSim — שלבים 4 ו־5

סטטוס הכנה: 17.08.2026 22:09 IDT. שלוש הבדיקות עברו בהרצה אוטומטית, וכל
עשר בדיקות הרגרסיה של שלבים 0–5 עברו. ההרצה הבאה מיועדת לשמירת ראיות GUI.

## הכנה

בחלון Transcript של ModelSim יש לוודא שהתיקייה היא:

```tcl
cd {C:/Users/noam1/Desktop/VHDL Lab/Final proj/SIM/RV32IMscMCU}
```

לפני כל script מריצים `quit -sim`, כדי לשחרר את ספריית `work` מהסימולציה
הקודמת. אין צורך ליצור Project בתוך ModelSim.

## בדיקה 1 — שלב 4: Basic Timer

```tcl
quit -sim
do run_stage4_basic_timer.do
```

תוצאה תקינה:

```text
STAGE 4 BASIC TIMER PASS
```

הבדיקה מכסה:

- פענוח ו־readback של כל רגיסטרי הטיימר ו־BTCLR שחוזר אוטומטית לאפס.
- ארבע בחירות השעון: `sysclk`, ‏`/2`, ‏`/4`, ‏`/8`.
- `BTHOLD`, איפוס המונה ו־compare תקופתי דרך `BTCMPR0`.
- PWM בשני מצבי `BTOUTMD`, מעבר ב־`BTCMPR1` ושמירת הפלט כאשר `BTOUTEN=0`.
- Capture בקצה עולה מ־CAPIN1 ובקצה יורד מ־CAPIN2.
- בחירת אירוע הטיימר באמצעות `BTINT` ושמירת הערך ב־`BTCAPR`.

ב־Wave יש לראות במיוחד את `counter`, ‏`pwm`, ‏`compare0_event`,
`compare1_event`, ‏`capture_event`, ‏`timer_event` ו־`capture_value`.

## בדיקה 2 — שלב 5: Pushbuttons

```tcl
quit -sim
do run_stage5_pushbuttons.do
```

תוצאה תקינה:

```text
STAGE 5 PUSHBUTTONS PASS
```

הבדיקה מכסה פולריות active-low, שני שלבי synchronizer, דחיית bounce, לחיצה
יציבה, לחיצה ארוכה ללא אירועים חוזרים, שחרור ללא אירוע press, לחיצה בו־זמנית
על שני כפתורים וקריאת `PORT_PB` ב־`0x2014`.

ב־Wave יש לראות את `keys_n`, ‏`key_sync1_n_q`, ‏`key_sync2_n_q`,
`buttons`, ‏`press_event` ומוני האירועים של שלושת הכפתורים.

## בדיקה 3 — אינטגרציית שלבים 4–5 ו־MMIO

```tcl
quit -sim
do run_stage4_5_peripheral_integration.do
```

תוצאה תקינה:

```text
STAGE 4/5 PERIPHERAL INTEGRATION PASS
```

הבדיקה מוודאת שה־MMIO mux החדש אינו שובר את GPIO, ושגישות ל־LEDR, ל־SW,
לטיימר ול־PORT_PB חוזרות מהמקור היחיד הנכון. בנוסף נבדקים PWM, אירוע timer,
מצב כפתור מסונן וקריאה לא ממופה שמחזירה אפס ללא `hit`.

## מה לשמור

לכל בדיקה יש ליצור תיקיית ראיות נפרדת תחת
`SIM/RV32IMscMCU/screenshots`:

- `stage4_basic_timer`
- `stage5_pushbuttons`
- `stage4_5_peripheral_integration`

בכל תיקייה שמור:

1. צילום מסך שבו רואים את הודעת ה־PASS ואת ה־Wave.
2. Wave format כקובץ `.do` מתוך `File > Save Format` בחלון Wave.
3. List format: כל script יוצר אוטומטית בתיקיית הסימולציה קובץ בשם
   `stage4_basic_timer_list.do`, ‏`stage5_pushbuttons_list.do` או
   `stage4_5_peripheral_integration_list.do`; העתק אותו לתיקיית הראיות שלו.

אם מתקבלת `Failure` או `Error`, עוצרים ולא ממשיכים לבדיקה הבאה. יש לשלוח את
כל ה־Transcript ואת שם ה־script שנכשל. אזהרת WLF על קובץ שכבר פתוח אינה כשל
לוגי; במקרה כזה סוגרים סימולציה אחרת או מריצים שוב אחרי `quit -sim`.

לאחר שלושת ה־PASSים נעדכן את שלבים 4–5 ל־complete, נכין את תוכנית המעבדה
הפיזית של שלב 5.5, ורק לאחר מכן נממש ונכין את בדיקות שלבים 6–7.
