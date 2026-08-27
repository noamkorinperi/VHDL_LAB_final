# בדיקות ModelSim — שלבים 6 ו־7

סטטוס הכנה: 17.08.2026 22:57 IDT. שתי הבדיקות עברו בהרצה אוטומטית. ההרצה
של המשתמש מיועדת לשמירת ראיות GUI ולסגירה פורמלית של השלבים.

## הכנה

ב־Transcript של ModelSim:

```tcl
cd {C:/Users/noam1/Desktop/VHDL Lab/Final proj/SIM/RV32IMscMCU}
```

לפני כל בדיקה מריצים `quit -sim`. אין צורך ליצור ModelSim Project ואין
צורך לשנות קובצי HEX ידנית.

## בדיקה 1 — שלב 6: Interrupt Controller

```tcl
quit -sim
do run_stage6_interrupt_controller.do
```

תוצאה תקינה:

```text
STAGE 6 INTERRUPT CONTROLLER PASS
```

הבדיקה מכסה את כתובות `IE=0x202C`, ‏`IFG=0x202D`, ‏`TYPE=0x202E`, mask,
יצירת IFG רק כאשר ה־IE המתאים פעיל, ניקוי IFG כש־IE מתבטל, חסימת `INTR`
כאשר GIE=0, ותעדוף:

```text
Timer (0x10) > KEY1 (0x14) > KEY2 (0x18) > KEY3 (0x1C)
```

בנוסף נבדקים clear אוטומטי של timer בזמן `INTA`, clear תוכנתי של flags של
הכפתורים, ואירוע חדש שמגיע באותו מחזור של clear.

ב־Wave בדוק במיוחד את `timer_event`, ‏`key_event`, ‏`ie_value`, ‏`ifg_value`,
`gie`, ‏`intr`, ‏`inta` ו־`irq_type`.

## בדיקה 2 — שלב 7: CPU Interrupt Integration

```tcl
quit -sim
do run_stage7_cpu_interrupt_integration.do
```

תוצאה תקינה:

```text
STAGE 7 CPU INTERRUPT INTEGRATION PASS
```

הבדיקה מריצה את benchmark הפסיקות `test2` שסופק, ולא תוכנית צעצוע. ה־TB:

- ממתין שהתוכנה תכתוב `IE=0x3C` ותגדיר `gp[0]=GIE=1`.
- לוחץ ומשחרר KEY1, ‏KEY2 ו־KEY3 בנפרד; אירוע הפסיקה נוצר בשחרור.
- מאמת `INTA`, לכידת TYPE המתאים וקפיצה דרך vector table שב־DTCM.
- מאמת ש־GIE מתאפס בזמן כניסה לפסיקה.
- מאמת שכל ISR כותב `state=1/2/3`, מנקה את ה־IFG שלו ומבצע `reti`.
- מאמת שהחזרה דרך `tp` היא ל־PC שהוחזק בזמן הכניסה וש־GIE חוזר ל־1.

ב־Wave בדוק את `pc`, ‏`instruction`, ‏`intr`, ‏`inta`, ‏`gie`, ‏`irq_active`,
`irq_type`, ‏`interrupt_ie`, ‏`interrupt_ifg`, ‏`keys_n`, ‏`bus_addr`,
`bus_wdata`, ‏`bus_write`.

## בדיקת קבלה — פסיקה שמגיעה באמצע DIV

```tcl
quit -sim
do run_stage7_divider_interrupt_order.do
```

הבדיקה מעלה פסיקה בזמן `DIV`, מוודאת שהחלוקה מסתיימת ונכתבת חזרה לפני
`INTA`, ואז מאמתת כניסה ל־ISR, חזרה דרך `tp` והמשך הזרימה ששומרת את המנה.
התוצאה התקינה היא `STAGE 7 DIVIDER/INTERRUPT ORDER PASS`.

## שמירת ראיות

צור שתי תיקיות:

```text
SIM/RV32IMscMCU/screenshots/stage6_interrupt_controller
SIM/RV32IMscMCU/screenshots/stage7_cpu_interrupt_integration
```

בכל תיקייה שמור צילום מסך שבו רואים PASS ו־Wave, וקובץ Wave באמצעות
`File > Save Format`. כל script יוצר אוטומטית קובץ List בתיקיית הסימולציה:

- `stage6_interrupt_controller_list.do`
- `stage7_cpu_interrupt_integration_list.do`

העתק כל List לתיקיית הראיות המתאימה. אם מתקבל `Failure` או `Error`, עצור
ושלח את כל ה־Transcript; אזהרות X/U ב־0 ps או WLF נעול אינן כשל אם מתקבל PASS.
