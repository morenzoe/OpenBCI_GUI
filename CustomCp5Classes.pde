//=======================================================================================================================================
//
//                    Custom Cp5 Classes and Methods
//
//  Created: Conor Russomanno Oct. 2014
//  Refactored: Richard Waltman Nov. 2020  
//
//=======================================================================================================================================

//Reusable method for creating CP5 buttons throughout the GUI
public Button createButton(ControlP5 _cp5, String name, String text, int _x, int _y, int _w, int _h, int _roundness, PFont _font, int _fontSize, color _bgColor, color _textColor, color _colorHover, color _colorPressed, Integer _strokeColor, int _marginTop) {
    final Button b = _cp5.addButton(name)
        .setPosition(_x, _y)
        .setSize(_w, _h)
        .setColorLabel(_textColor)
        .setCornerRoundness(_roundness) //From Processing rect(): To draw a rounded rectangle, add a fifth parameter, which is used as the radius value for all four corners.
        .setColorForeground(_colorHover)
        .setColorBackground(_bgColor)
        .setColorActive(_colorPressed)
        .setBorderColor(_strokeColor)
        ;
    b.getCaptionLabel()
        .setFont(_font)
        .toUpperCase(false)
        .setSize(_fontSize)
        .setText(text)
        .setColor(_textColor) //This sets the color of the button label
        .getStyle()
        .setMarginTop(_marginTop)
        ;
    //Add Help Text to all Buttons. If description is null or object is locked, take no action.
    b.addCallback(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            if (theEvent.getAction() == ControlP5.ACTION_ENTER && !b.isLock() && b.getDescription() != null) {
                //Show helpt text if object is not locked and has a description
                buttonHelpText.setButtonHelpText(b.getDescription(), (int)b.getPosition()[0] + b.getWidth()/2, (int)b.getPosition()[1] + (3*b.getHeight())/4);
                buttonHelpText.setTimeUserEnteredUIObject();
            } else if (theEvent.getAction() == ControlP5.ACTION_LEAVE || theEvent.getAction() == ControlP5.ACTION_BROADCAST) {
                //Hide help text if clicked or user's mouse leaves object
                buttonHelpText.setVisible(false);
            }
        }
    });
    return b;
}

//Square corners and no text label adjustment w/ default hover and press colors
public Button createButton(ControlP5 _cp5, String name, String text, int _x, int _y, int _w, int _h, PFont _font, int _fontSize, color _bgColor, color _textColor) {
    return createButton(_cp5, name, text, _x, _y, _w, _h, 0, _font, _fontSize, _bgColor, _textColor, BUTTON_HOVER, BUTTON_PRESSED, OPENBCI_DARKBLUE, 0);
}

//Default button colors and fonts
private Button createButton(ControlP5 _cp5, String name, String text, int _x, int _y, int _w, int _h) {
    return createButton(_cp5, name, text, _x, _y, _w, _h, 0, p5, 12, colorNotPressed, OPENBCI_DARKBLUE, BUTTON_HOVER, BUTTON_PRESSED, OPENBCI_DARKBLUE, 0);
}


///////////////////////////////////////////////////////
//              BUTTON HELP TEXT CLASS               //
///////////////////////////////////////////////////////
class ButtonHelpText{
    private int x, y, w, h;
    private String myText = "";
    private boolean isVisible;
    private int numLines;
    private int lineSpacing = 14;
    private int padding = 10;
    private int timeUserEnteredUIObject;
    private final int delay = 1000;
    private final int fadeInTime = 500;
    private float masterOpacity;

    ButtonHelpText(){

    }

    public void setTimeUserEnteredUIObject() {
        timeUserEnteredUIObject = millis();
        isVisible = true;
    }

    public void setVisible(boolean _isVisible){
        isVisible = _isVisible;
    }

    public void setButtonHelpText(String _myText, int _x, int _y){
        myText = _myText;
        x = _x;
        y = _y;
    }

    public void draw(){
        //When using expert mode, disable help text over UI objects
        if (!isVisible || guiSettings.getExpertModeBoolean()) {
            return;
        }

        int delta = millis() - timeUserEnteredUIObject;
        boolean timeToShowHelpText =  delta > delay;

        if (timeToShowHelpText) {
            
            //Fade in the help text
            masterOpacity = (delta < delay + fadeInTime) ? map(delta, delay, delay + fadeInTime, 0, 255) : 255f;

            pushStyle();
            textAlign(CENTER, TOP);

            textFont(p5,12);
            textLeading(lineSpacing); //line spacing
            stroke(31,69,110, masterOpacity);
            fill(255, masterOpacity);
            numLines = (int)((float)myText.length()/30.0) + 1; //add 1 to round up
            // println("numLines: " + numLines);
            //if on left side of screen, draw box brightness to prevent box off screen
            if(x <= width/2){
                rect(x, y, 200, 2*padding + numLines*lineSpacing + 4);
                fill(31,69,110, masterOpacity); //text color
                text(myText, x + padding, y + padding, 180, (numLines*lineSpacing + 4));
            } else{ //if on right side of screen, draw box left to prevent box off screen
                rect(x - 200, y, 200, 2*padding + numLines*lineSpacing + 4);
                fill(OPENBCI_BLUE); //text color
                text(myText, x + padding - 200, y + padding, 180, (numLines*lineSpacing + 4));
            }
            popStyle();
        }
    }
};

////////////////////////////////////////////////////////////////////////////////////
//                              MENULIST CLASS                                    //
//   Based on ControlP5 Processing Library example, written by Andreas Schlegel   //
//      WARNING: This class does not respond well to being resized -RW 5/5/23     //
////////////////////////////////////////////////////////////////////////////////////
public class MenuList extends controlP5.Controller {

    float pos, npos;
    int itemHeight = 24;
    int scrollerLength = 40;
    int scrollerWidth = 15;
    List< Map<String, Object>> items = new ArrayList< Map<String, Object>>();
    PGraphics menu;
    boolean updateMenu;
    int hoverItem = -1;
    int activeItem = -1;
    PFont menuFont;
    int padding = 7;

    MenuList(ControlP5 c, String theName, int theWidth, int theHeight, PFont theFont) {

        super( c, theName, 0, 0, theWidth, theHeight );
        c.register( this );
        menu = createGraphics(getWidth(),getHeight());
        final ControlP5 cc = c; //allows check for isLocked() below
        final String _theName = theName;

        menuFont = theFont;

        setView(new ControllerView<MenuList>() {

            public void display(PGraphics pg, MenuList t) {
                if (updateMenu && !cc.get(MenuList.class, _theName).isLock()) {
                    updateMenu();
                }
                if (isMouseOver()) {
                    menu.beginDraw();
                    int len = -(itemHeight * items.size()) + getHeight();
                    int ty;
                    if(len != 0){
                        ty = int(map(pos, len, 0, getHeight() - scrollerLength - 2, 2 ) );
                    } else {
                        ty = 0;
                    }
                    menu.fill(OPENBCI_DARKBLUE, 100);
                    if(ty > 0){
                        menu.rect(getWidth()-scrollerWidth-2, ty, scrollerWidth, scrollerLength );
                    }
                    menu.endDraw();
                }
                pg.image(menu, 0, 0);
            }
        }
        );
        updateMenu();
    }

    //only update the image buffer when necessary - to save some resources
    void updateMenu() {
        int len = -(itemHeight * items.size()) + getHeight();
        npos = constrain(npos, len, 0);
        pos += (npos - pos) * 0.1;
        //    pos += (npos - pos) * 0.1;
        menu.beginDraw();
        menu.noStroke();
        menu.background(255, 64);
        // menu.textFont(cp5.getFont().getFont());
        menu.textFont(menuFont);
        menu.pushMatrix();
        menu.translate( 0, pos );
        menu.pushMatrix();

        int i0;
        if((itemHeight * items.size()) != 0){
            i0 = PApplet.max( 0, int(map(-pos, 0, itemHeight * items.size(), 0, items.size())));
        } else{
            i0 = 0;
        }
        int range = ceil((float(getHeight())/float(itemHeight))+1);
        int i1 = PApplet.min( items.size(), i0 + range );

        menu.translate(0, i0*itemHeight);

        for (int i=i0; i<i1; i++) {
            Map m = items.get(i);
            menu.fill(255, 100);
            if (i == hoverItem) {
                menu.fill(127, 134, 143);
            }
            if (i == activeItem) {
                menu.stroke(TURN_ON_GREEN);
                menu.strokeWeight(1);
                menu.fill(TURN_ON_GREEN);
                menu.rect(0, 0, getWidth()-1, itemHeight-1 );
                menu.noStroke();
            } else {
                menu.rect(0, 0, getWidth(), itemHeight-1 );
            }
            menu.fill(OPENBCI_DARKBLUE);
            menu.textFont(menuFont);

            //make sure there is something in the Ganglion serial list...
            try {
                menu.text(m.get("headline").toString(), 8, itemHeight - padding); // 5/17
                menu.translate( 0, itemHeight );
            } catch(Exception e){
                println("Nothing in list...");
            }
        }
        menu.popMatrix();
        menu.popMatrix();
        menu.endDraw();
        updateMenu = abs(npos-pos)>0.01 ? true:false;
    }

    // When detecting a click, check if the click happend to the far right, if yes, scroll to that position,
    // Otherwise do whatever this item of the list is supposed to do.
    public void onClick() {
        println(getName() + ": click! ");
        if (items.size() > 0) { //Fixes #480
            if (getPointer().x()>getWidth()-scrollerWidth) {
                if(getHeight() != 0){
                    npos= -map(getPointer().y(), 0, getHeight(), 0, items.size()*itemHeight);
                }
                updateMenu = true;
            } else {
                int len = itemHeight * items.size();
                int index = 0;
                if(len != 0){
                    index = int( map( getPointer().y() - pos, 0, len, 0, items.size() ) ) ;
                }
                setValue(index);
                activeItem = index;
            }
            updateMenu = true;
        }
    }

    public void onMove() {
        if (getPointer().x()>getWidth() || getPointer().x()<0 || getPointer().y()<0  || getPointer().y()>getHeight() ) {
            hoverItem = -1;
        } else {
            int len = itemHeight * items.size();
            int index = 0;
            if(len != 0){
                index = int( map( getPointer().y() - pos, 0, len, 0, items.size() ) ) ;
            }
            hoverItem = index;
        }
        updateMenu = true;
    }

    public void onDrag() {
        if (getPointer().x() > (getWidth()-scrollerWidth)) {
            npos= -map(getPointer().y(), 0, getHeight(), 0, items.size()*itemHeight);
            updateMenu = true;
        } else {
            npos += getPointer().dy() * 2;
            updateMenu = true;
        }
    }

    public void onScroll(int n) {
        npos += ( n * 4 );
        updateMenu = true;
    }

    public void addItem(Map<String, Object> m) {
        items.add(m);
        updateMenu = true;
    }

    public void addItem(String theHeadline) {
        Map m = new HashMap<String, Object>();
        m.put("headline", theHeadline);
        addItem(m);
    }

    public void addItem(String theHeadline, int value) {
        Map m = new HashMap<String, Object>();
        m.put("headline", theHeadline);
        m.put("value", value);
        items.add(m);
    }

    public void addItem(String theHeadline, String theSubline, String theCopy) {
        Map m = new HashMap<String, Object>();
        m.put("headline", theHeadline);
        m.put("subline", theSubline);
        m.put("copy", theCopy);
        items.add(m);
    }

    public void removeItem(Map<String, Object> m) {
        items.remove(m);
        updateMenu = true;
    }

    //Returns null if selecting an item that does not exist
    public Map<String, Object> getItem(int theIndex) {
        Map<String, Object> m = new HashMap<String, Object>();
        try {
            m = items.get(theIndex);
        } catch (Exception e) {
            //println("Item " + theIndex + " does not exist.");
        }
        return m;
    }

    public int getListSize() {
       return items.size(); 
    }
};

////////////////////////////////////////////////////////////////
//                      GUI CopyPaste                         //
// Custom class used by the GUI to handle both Copy and Paste //
// Use standard copy and paste keyboard shortcuts for all OS  //
//                                                            //
// Copy ControlP5 Textfield Text                              //
//      - Windows and Linux: Control + C                      //
//      - Mac: Command + C                                    //
// Paste Text into Textfield                                  //
//      - Windows and Linux: Control + V                      //
//      - Mac: Command + V                                    //
////////////////////////////////////////////////////////////////
class CopyPaste {

    private final int CMD_CNTL_KEYCODE = (isLinux() || isWindows()) ? 17 : 157;
    private final int C_KEYCODE = 67;
    private final int V_KEYCODE = 86;
    private boolean commandControlPressed;
    private boolean copyPressed;
    private String value;

    CopyPaste () {

    }
    
    public boolean checkIfPressedAllOS() {
        //This logic mimics the behavior of copy/paste in Mac OS X, and applied to all.
        if (keyCode == CMD_CNTL_KEYCODE) {
            commandControlPressed = true;
            //println("KEYBOARD SHORTCUT: COMMAND PRESSED");
            return true;
        }

        if (commandControlPressed && keyCode == V_KEYCODE) {
            //println("KEYBOARD SHORTCUT: PASTE PRESSED");
            // Get clipboard contents
            String s = GClip.paste();
            //println("FROM CLIPBOARD ~~ " + s);
            // Assign to stored value
            value = s;
            return true;
        }

        if (commandControlPressed && keyCode == C_KEYCODE) {
            //println("KEYBOARD SHORTCUT: COPY PRESSED");
            copyPressed = true;
            return true;
        }

        return false;
    }

    public void checkIfReleasedAllOS() {
        if (keyCode == CMD_CNTL_KEYCODE) {
            commandControlPressed = false;
        }
    }
    
    //Pull stored value from this class and set to null, otherwise return null.
    private String pullValue() {
        if (value == null) {
            return value;
        }
        String s = value;
        value = null;
        return s;
    }

    private void checkForPaste(Textfield tf) {
        if (value == null) {
            return;
        }

        if (tf.isFocus()) {
            StringBuilder status = new StringBuilder("OpenBCI_GUI: User pasted text from the clipboard into ");
            status.append(tf.toString());
            println(status);
            StringBuilder sb = new StringBuilder();
            String existingText = dropNonPrintableChars(tf.getText());
            String val = pullValue();
            //println("EXISTING TEXT =="+ existingText+ "__end. VALUE ==" + val + "__end.");

            // On Mac, Remove 'v' character from the end of the existing text
            existingText = existingText.length() > 0 && isMac() ? existingText.substring(0, existingText.length() - 1) : existingText;

            sb.append(existingText);
            sb.append(val);
            //The 'v' character does make it to the textfield, but this is immediately overwritten here.
            tf.setText(sb.toString());
        } 
    }

    private void checkForCopy(Textfield tf) {
        if (!copyPressed) {
            return;
        }

        if (tf.isFocus()) {
            String s = dropNonPrintableChars(tf.getText());
            if (s.length() == 0) {
                return;
            }
            StringBuilder status = new StringBuilder("OpenBCI_GUI: User copied text from ");
            status.append(tf.toString());
            status.append(" to the clipboard");
            println(status);
            //println("FOUND TEXT =="+ s+"__end.");
            if (isMac()) {
                //Remove the 'c' character that was just typed in the textfield
                s = s.substring(0, s.length() - 1);
                tf.setText(s);
                //println("MAC FIXED TEXT =="+ s+"__end.");
            }
            boolean b = GClip.copy(s);
            copyPressed = false;
        } 
    }

    public void checkForCopyPaste(Textfield tf) {
        checkForPaste(tf);
        checkForCopy(tf);
    }
}

//Cp5 Textfield helper class
public class TextFieldUpdateHelper {

    // textFieldIsActive is used to ignore hotkeys when a textfield is active. Resets to false on every draw loop.
    private boolean textFieldIsActive = false;

    TextFieldUpdateHelper() {

    }
    
    public void resetTextFieldIsActive() {
        textFieldIsActive = false;
    }

    public boolean getAnyTextfieldsActive() {
        return textFieldIsActive;
    }

    public void checkTextfield(Textfield tf) {
        if (tf.isVisible()) {
            tf.setUpdate(true);
            if (tf.isFocus()) {
                textFieldIsActive = true;
                copyPaste.checkForCopyPaste(tf);
            }
        } else {
            tf.setUpdate(false);
        }
    }
}
