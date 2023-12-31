
////////////////////////////////////////////////////
//
//    W_PulseSensor.pde
//
//    Created: Joel Murphy, Spring 2017
//
///////////////////////////////////////////////////,

class W_PulseSensor extends Widget {

    //to see all core variables/methods of the Widget class, refer to Widget.pde
    //put your custom variables here...
    color graphStroke = #d2d2d2;
    color graphBG = #f5f5f5;
    color textColor = #000000;

    // Pulse Sensor Visualizer Stuff
    int count = 0;
    int heart = 0;
    int PulseBuffSize = 3*currentBoard.getSampleRate(); // Originally 400
    int BPMbuffSize = 100;

    int PulseWindowWidth;
    int PulseWindowHeight;
    int PulseWindowX;
    int PulseWindowY;
    int BPMwindowWidth;
    int BPMwindowHeight;
    int BPMwindowX;
    int BPMwindowY;
    int BPMposX;
    int BPMposY;
    int IBIposX;
    int IBIposY;
    int padding = 15;
    color eggshell;
    color pulseWave;
    int[] PulseWaveY;      // HOLDS HEARTBEAT WAVEFORM DATA
    int[] BPMwaveY;        // HOLDS BPM WAVEFORM DATA
    boolean rising;

    // Synthetic Wave Generator Stuff
    float theta;  // Start angle at 0
    float amplitude;  // Height of wave
    int syntheticMultiplier;
    long thisTime;
    long thatTime;
    int refreshRate;

    // Pulse Sensor Beat Finder Stuff
    // ASSUMES 250Hz SAMPLE RATE
    int[] rate;                    // array to hold last ten IBI values
    int sampleCounter;          // used to determine pulse timing
    int lastBeatTime;           // used to find IBI
    int P =512;                      // used to find peak in pulse wave, seeded
    int T = 512;                     // used to find trough in pulse wave, seeded
    int thresh = 530;                // used to find instant moment of heart beat, seeded
    int amp = 0;                   // used to hold amplitude of pulse waveform, seeded
    boolean firstBeat = true;        // used to seed rate array so we startup with reasonable BPM
    boolean secondBeat = false;      // used to seed rate array so we startup with reasonable BPM
    int BPM;                   // int that holds raw Analog in 0. updated every 2mS
    int Signal;                // holds the incoming raw data
    int IBI = 600;             // int that holds the time interval between beats! Must be seeded!
    boolean Pulse = false;     // "True" when User's live heartbeat is detected. "False" when not a "live beat".
    int lastProcessedDataPacketInd = 0;
    private Button analogModeButton;

    private AnalogCapableBoard analogBoard;

    W_PulseSensor(PApplet _parent){
        super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

        analogBoard = (AnalogCapableBoard)currentBoard;

        // Pulse Sensor Stuff
        eggshell = color(255, 253, 248);
        pulseWave = BOLD_RED;

        PulseWaveY = new int[PulseBuffSize];
        BPMwaveY = new int[BPMbuffSize];
        rate = new int[10];
        setPulseWidgetVariables();
        initializePulseFinderVariables();

        createAnalogModeButton("pulseSensorAnalogModeButton", "Turn Analog Read On", (int)(x0 + 1), (int)(y0 + navHeight + 1), 128, navHeight - 3, p5, 12, colorNotPressed, OPENBCI_DARKBLUE);
    }

    void update(){
        super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

        if(currentBoard instanceof DataSourcePlayback) {
            if (((DataSourcePlayback)currentBoard) instanceof AnalogCapableBoard
                && (!((AnalogCapableBoard)currentBoard).isAnalogActive())) {
                    return;
            }
        }

        List<double[]> allData = currentBoard.getData(PulseBuffSize);
        int[] analogChannels = analogBoard.getAnalogChannels();

        for (int i=0; i < PulseBuffSize; i++ ) {
            int signal = (int)(allData.get(i)[analogChannels[0]]);
            //processSignal(signal);
            PulseWaveY[i] = signal;
        }

        double[][] frameData = currentBoard.getFrameData();
        for (int i = 0; i < frameData[0].length; i++)
        {
            int signal = (int)(frameData[analogChannels[0]][i]);
            processSignal(signal);
        }

        //ignore top left button interaction when widgetSelector dropdown is active
        List<controlP5.Controller> cp5ElementsToCheck = new ArrayList<controlP5.Controller>();
        cp5ElementsToCheck.add((controlP5.Controller)analogModeButton);
        lockElementsOnOverlapCheck(cp5ElementsToCheck);

        if (!analogBoard.canDeactivateAnalog()) {
            analogModeButton.setLock(true);
            analogModeButton.getCaptionLabel().setText("Analog Read On");
            analogModeButton.setColorBackground(BUTTON_LOCKED_GREY);
        }
    }

    private void updateOnOffButton() {
        if (analogBoard.isAnalogActive()) {	
            
            analogModeButton.setOn();
        }
        else {
            	
            analogModeButton.setOff();
        }
    }

    void addBPM(int bpm) {
        for(int i=0; i<BPMwaveY.length-1; i++){
            BPMwaveY[i] = BPMwaveY[i+1];
        }
        BPMwaveY[BPMwaveY.length-1] = bpm;
    }

    void draw(){
        super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)
        //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        pushStyle();

        fill(graphBG);
        stroke(graphStroke);
        rect(PulseWindowX,PulseWindowY,PulseWindowWidth,PulseWindowHeight);
        rect(BPMwindowX,BPMwindowY,BPMwindowWidth,BPMwindowHeight);

        fill(50);
        textFont(p4, 16);
        textAlign(LEFT,CENTER);
        text("BPM "+BPM, BPMposX, BPMposY);
        text("IBI "+IBI+"mS", IBIposX, IBIposY);

        if (analogBoard.isAnalogActive()) {
            drawWaves();
        }

        popStyle();

    }

    void screenResized(){
        super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

        setPulseWidgetVariables();
        analogModeButton.setPosition((int)(x0 + 1), (int)(y0 + navHeight + 1));
    }

    void mousePressed(){
        super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)
    }

    void mouseReleased(){
        super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)
    }

    void createAnalogModeButton(String name, String text, int _x, int _y, int _w, int _h, PFont _font, int _fontSize, color _bg, color _textColor) {
        analogModeButton = createButton(cp5_widget, name, text, _x, _y, _w, _h, 0, _font, _fontSize, _bg, _textColor, BUTTON_HOVER, BUTTON_PRESSED, OBJECT_BORDER_GREY, 0);
        analogModeButton.setSwitch(true);
        analogModeButton.onRelease(new CallbackListener() {
            public void controlEvent(CallbackEvent theEvent) {
                if (!analogBoard.isAnalogActive()) {
                    analogBoard.setAnalogActive(true);
                    analogModeButton.getCaptionLabel().setText("Turn Analog Read Off");	
                    output("Starting to read analog inputs on pin marked D11.");
                    w_analogRead.toggleAnalogReadButton(true);
                    w_accelerometer.accelBoardSetActive(false);
                    w_digitalRead.toggleDigitalReadButton(false);
                } else {
                    analogBoard.setAnalogActive(false);
                    analogModeButton.getCaptionLabel().setText("Turn Analog Read On");
                    output("Starting to read accelerometer");
                    w_analogRead.toggleAnalogReadButton(false);
                    w_accelerometer.accelBoardSetActive(true);
                    w_digitalRead.toggleDigitalReadButton(false);
                }
            }
        });
        String _helpText = (selectedProtocol == BoardProtocol.WIFI) ? 
            "Click this button to activate/deactivate analog read on Cyton pins A5(D11) and A6(D12)." :
            "Click this button to activate/deactivate analog read on Cyton pins A5(D11), A6(D12) and A7(D13)."
            ;
        analogModeButton.setDescription(_helpText);
    }

    public void toggleAnalogReadButton(boolean _value) {
        String s = _value ? "Turn Analog Read Off" : "Turn Analog Read On";
        analogModeButton.getCaptionLabel().setText(s);
        if (_value) {
            analogModeButton.setOn();
        } else {
            analogModeButton.setOff();
        }
    }

    //add custom functions here
    void setPulseWidgetVariables(){
        PulseWindowWidth = ((w/4)*3) - padding;
        PulseWindowHeight = h - padding *2;
        PulseWindowX = x + padding;
        PulseWindowY = y + h - PulseWindowHeight - padding;

        BPMwindowWidth = w/4 - (padding + padding/2);
        BPMwindowHeight = PulseWindowHeight; // - padding;
        BPMwindowX = PulseWindowX + PulseWindowWidth + padding/2;
        BPMwindowY = PulseWindowY; // + padding;

        BPMposX = BPMwindowX + padding/2;
        BPMposY = y - padding; // BPMwindowHeight + int(float(padding)*2.5);
        IBIposX = PulseWindowX + PulseWindowWidth/2; // + padding/2
        IBIposY = y - padding;
    }

    void initializePulseFinderVariables(){
        sampleCounter = 0;
        lastBeatTime = 0;
        P = 512;
        T = 512;
        thresh = 530;
        amp = 0;
        firstBeat = true;
        secondBeat = false;
        BPM = 0;
        Signal = 512;
        IBI = 600;
        Pulse = false;

        theta = 0.0;
        amplitude = 300;
        syntheticMultiplier = 1;

        thatTime = millis();

        for(int i=0; i<PulseWaveY.length; i++){
            PulseWaveY[i] = Signal;
        }

        for(int i=0; i<BPMwaveY.length; i++){
            BPMwaveY[i] = BPM;
        }

    }

    void drawWaves(){
        int xi, yi;
        noFill();
        strokeWeight(1);
        stroke(pulseWave);
        beginShape();                                  // using beginShape() renders fast
        for(int i=0; i<PulseWaveY.length; i++){
            xi = int(map(i,0, PulseWaveY.length-1,0, PulseWindowWidth-1));
            xi += PulseWindowX;
            yi = int(map(PulseWaveY[i],0.0,1023.0,
                float(PulseWindowY + PulseWindowHeight),float(PulseWindowY)));
            vertex(xi, yi);
        }
        endShape();

        strokeWeight(2);
        stroke(pulseWave);
        beginShape();                                  // using beginShape() renders fast
        for(int i=0; i<BPMwaveY.length; i++){
            xi = int(map(i,0, BPMwaveY.length-1,0, BPMwindowWidth-1));
            xi += BPMwindowX;
            yi = int(map(BPMwaveY[i], 0.0,200.0,
                float(BPMwindowY + BPMwindowHeight), float(BPMwindowY)));
            vertex(xi, yi);
        }
        endShape();

    }

    // THIS IS THE BEAT FINDING FUNCTION
    // BASED ON CODE FROM World Famous Electronics, MAKERS OF PULSE SENSOR
    // https://github.com/WorldFamousElectronics/PulseSensor_Amped_Arduino
    void processSignal(int sample){                         // triggered when Timer2 counts to 124
        // cli();                                      // disable interrupts while we do this
        // Signal = analogRead(pulsePin);              // read the Pulse Sensor
        sampleCounter += (4 * syntheticMultiplier);                         // keep track of the time in mS with this variable
        int N = sampleCounter - lastBeatTime;       // monitor the time since the last beat to avoid noise

            //  find the peak and trough of the pulse wave
        if(sample < thresh && N > (IBI/5)*3){       // avoid dichrotic noise by waiting 3/5 of last IBI
            if (sample < T){                        // T is the trough
                T = sample;                         // keep track of lowest point in pulse wave
            }
        }

        if(sample > thresh && sample > P){          // thresh condition helps avoid noise
            P = sample;                             // P is the peak
        }                                        // keep track of highest point in pulse wave

        //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
        // signal surges up in value every time there is a pulse
        if (N > 250){                                   // avoid high frequency noise
            if ( (sample > thresh) && (Pulse == false) && (N > (IBI/5)*3) ){
                Pulse = true;                               // set the Pulse flag when we think there is a pulse
                IBI = sampleCounter - lastBeatTime;         // measure time between beats in mS
                lastBeatTime = sampleCounter;               // keep track of time for next pulse

                if(secondBeat){                        // if this is the second beat, if secondBeat == TRUE
                    secondBeat = false;                  // clear secondBeat flag
                    for(int i=0; i<=9; i++){             // seed the running total to get a realisitic BPM at startup
                        rate[i] = IBI;
                    }
                }

                if(firstBeat){                         // if it's the first time we found a beat, if firstBeat == TRUE
                    firstBeat = false;                   // clear firstBeat flag
                    secondBeat = true;                   // set the second beat flag
                    // sei();                               // enable interrupts again
                    return;                              // IBI value is unreliable so discard it
                }


                // keep a running total of the last 10 IBI values
                int runningTotal = 0;                  // clear the runningTotal variable

                for(int i=0; i<=8; i++){                // shift data in the rate array
                    rate[i] = rate[i+1];                  // and drop the oldest IBI value
                    runningTotal += rate[i];              // add up the 9 oldest IBI values
                }

                rate[9] = IBI;                          // add the latest IBI to the rate array
                runningTotal += rate[9];                // add the latest IBI to runningTotal
                runningTotal /= 10;                     // average the last 10 IBI values
                BPM = 60000/runningTotal;               // how many beats can fit into a minute? that's BPM!
                BPM = constrain(BPM,0,200);
                addBPM(BPM);
            }
        }

        if (sample < thresh && Pulse == true){   // when the values are going down, the beat is over
            // digitalWrite(blinkPin,LOW);            // turn off pin 13 LED
            Pulse = false;                         // reset the Pulse flag so we can do it again
            amp = P - T;                           // get amplitude of the pulse wave
            thresh = amp/2 + T;                    // set thresh at 50% of the amplitude
            P = thresh;                            // reset these for next time
            T = thresh;
        }

        if (N > 2500){                           // if 2.5 seconds go by without a beat
            thresh = 530;                          // set thresh default
            P = 512;                               // set P default
            T = 512;                               // set T default
            lastBeatTime = sampleCounter;          // bring the lastBeatTime up to date
            firstBeat = true;                      // set these to avoid noise
            secondBeat = false;                    // when we get the heartbeat back
        }

        // sei();                                   // enable interrupts when youre done!
    }// end processSignal


};
