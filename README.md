## Termirun-intergrated_code_runner_at_termux
```
- That is it, so far for termirun 1 series. Comming up Termirun_Light series and Termirun_Full series in the next repo

- Bugs concerning failure in execution of R, Fortran.
- There might be delay in detailed README within tha pack than the general README displayed below.
- Havent figured out how or where should Python libraries be installed here, so work conservatively with that.
- Planning to divide into a light version and a full version. 
  - The light version aims to simplify everything for users just want to run codes in 3 min after downloading and cares nothing else(computer students who want to do homeworks, like me). 
  - The full version will support custom  designation and configuration of compilers and recognttion of programming language to better and truly work as a capsule serving to manage and run codes effitiently. Maybe you can expect it a little bit.
- Be careful with all kinds of renaming operations concerning termirun related folders after configuration.
```

- Generated with Doubao A.I.

- `termirun.sh`, A ready-to-use Shell Script terminal tool aiming to run code files(`c,cpp,java,py,fortran,r` and extending...) using `Termux` on `Android(either root or unroot)` devices, convenitntly, by encasing the calls for multiple compilers into simple unified commands.

- Each `termirun` script works with 3 folders,  
(which are designated, so know where they are before initializaing termirun)   
(folder names just for comprehension, can be any name while using):  
  1. the "seat", where `termirun` script sits and your terminal `cd` at.(for unrooted users, should be under `～/` and given `chomod +777`)
  2. the "source" folder, where the source code files you work with is stored.(for unrooted users, should **NOT** be under `～/`, or regular code editors can't access your code files, you can't work with them)
  3. the "bins" folder, where the compile product is stored and executed from.(for unrooted users, should be under `～/` and given `chomod +777`)
  4. The termirun script, if set up properly, each time when tieggered, compiles one code file from your "source" folder to the "bins" folder and autometically executes it.

- Recommending `termirun`'s association with 
  - `Termux`, an app providing terminal (simulator) environment on Android, extremely powerful
  - `Acode`, an app code editor on Android, termirun is turining it into an IDE in some ways
  - `Acodex-Terminal`(optional), an plugin of Acode providing terminal(simulator) environment within Acode, so you don't need to switch between Termux and Acode per terminal execution
  - `MT Manager`(optional), an powerful file manager to distinctly show directories. Some Android official file managers tend to hide files, so MT Manager is a solution here.

- Do mind the mis-renaming, the script of all versions has fullname `termirun.sh`, not base name. The extra suffix `.sh` could be automatically attached druing transfer process(which makes the fullname`termirun.sh.sh`, which completely disables it). Some programmes might not acknowledge the ommition of `.sh`, but Termux is not one of them.
  - If its **visible** name on an Android device is `termirun.sh`, just rename it to `termirun` as there is a hidden `.sh` already, the icon might change, but trust me, it's fine.

- Beginner firendly(as you can tell I am a beginner myself)

- Secondary `README.md` file within the zip packages each,more detailed about settings, guidance, so on.
  
- The releases are in bilingual support, *Chinese* and *English*, identically functional.

- It is born only because the author simlpy wants to use his Android tablet to do coding works, and cannot find ways to simlpy set up a "run" button in Acode.

- Hell knows, it started in about 60 lines of codes okey, then 120, then 300, 500, 700, 1200, and I was like here goes nothing just say whethre its usable Fuiyoh~

- Praise( )king the king of( )

