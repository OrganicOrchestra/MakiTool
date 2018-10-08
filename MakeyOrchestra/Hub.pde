import processing.serial.*;
import java.util.Collections;

enum HubType {
  TRACK, TRIGGER, SWITCH
};

color[] hubColors = {color(50, 255, 0), color(50, 0, 255), color(255, 255, 0), color(255, 100, 0), color(0, 255, 255)};
boolean isDragging = false;

public class Hub extends PVector
{
  Serial port;
  HubType type;
  PApplet parent;

  int index;
  String portName;
  boolean isConnected;
  boolean autoMap = false;
  int numTracks;
  int startTrack;

  color hubColor;

  boolean[] trackActives;//not used in triggers
  float[] trackVolumes; //also used for trigger animations
  float[] trackDims; //for volume animation
  float[] trackAlphas; //for ui 
  PVector [] trackCenters; // for mouse interaction
  int selectedIdx;
  //serial
  int bufferIndex;
  int[] buffer;
  int[] portMap;
  ArrayList<Integer> recievedMakeysPins;

  boolean showText;

  public Hub(PApplet parent, int index, HubType type, int startTrack, int numTracks, String portName, int[] portMap)
  {
    println("New Hub ("+type+":"+portName+") : "+index+" "+startTrack+">"+numTracks);

    this.index = index;
    this.parent = parent;
    this.portName = portName;
    this.type = type;
    this.startTrack = startTrack;
    this.numTracks = numTracks;
    this.portMap = portMap;
    this.recievedMakeysPins = new ArrayList<Integer>();

    hubColor = hubColors[index % hubColors.length];

    trackActives = new boolean[numTracks];
    trackVolumes = new float[numTracks];
    trackAlphas = new float[numTracks];
    trackDims = new float[numTracks];
    trackCenters = new PVector[numTracks];
    selectedIdx = -1;
    for (int i=0; i<numTracks; i++)
    {
      trackAlphas[i] = 0;
      trackActives[i] = false;
      trackVolumes[i] = type == HubType.TRACK?1:0;
    }

    buffer = new int[32];


    showText = true;
    registerMethod("mouseEvent", this);
    connect();
    loadAutoMap();
  }
  public void reset()
  {
    for (int i=0; i<numTracks; i++)
    {
      trackAlphas[i] = 0;
      setTrackActive(i, false);
      setTrackVolume(i, 1);
    }
  }

  public void mouseEvent(MouseEvent event) {

    for (int i = 0; i  < numTracks; i++) {
      PVector tc = trackCenters[i];
      int mx = mouseX-width/2;
      int my= mouseY-height/2;
      float distFromTc =tc.copy().sub(mx, my).mag(); 
      if ((selectedIdx==-1 && distFromTc<flowerSize/2) || selectedIdx == i) {
        switch(event.getAction()) {
        case MouseEvent.PRESS:
          selectedIdx = i;
          break;

        case MouseEvent.RELEASE:
          if (selectedIdx!=-1 && !isDragging) {
            if (type == HubType.TRACK) toggleTrackActive(selectedIdx);
            else if (type == HubType.TRIGGER) triggerTrack(selectedIdx);
            else if (type == HubType.SWITCH) switchTrack(selectedIdx);
          }
          selectedIdx = -1;
          isDragging = false;
          break;

        case MouseEvent.DRAG:

          if (type==HubType.TRACK && selectedIdx!=-1) {
            isDragging = true;
            PVector mr = new PVector(mx-x, my-y);
            PVector c  = new PVector(tc.x-x, tc.y-y).normalize();
            float dist = mr.dot(c);
            float v = min(1, dist / flowerRadius);
            setTrackVolume(selectedIdx, v);
          }
          break;
        }
      }
    }
  } 

  public void draw()
  {
    //update volumes depending on dims
    for (int i=0; i<numTracks; i++)
    {
      if (trackDims[i] == 0) continue;
      setTrackVolume(i, trackVolumes[i] + trackDims[i]);
    }


    pushStyle();
    pushMatrix();
    translate(x, y);
    fill(hubColor);
    noStroke();
    ellipseMode(CENTER);
    ellipse(0, 0, flowerRadius/3, flowerRadius/3);

    for (int i=0; i<numTracks; i++)
    {
      float angle = (i*1.f/numTracks)*PI*2;
      float dist = type == HubType.TRACK?trackVolumes[i]:1; //0-1 depending on volume
      dist = map(dist, 0, 1, .2f, 1);
      trackAlphas[i] += (int(trackActives[i])-trackAlphas[i])*.2f;

      noFill();
      stroke(hubColor);
      strokeWeight(4);
      PVector trackEdge = new PVector(cos(angle)*(flowerRadius*dist-flowerSize/2), sin(angle)*(flowerRadius*dist-flowerSize/2));
      PVector trackCenter = new PVector(cos(angle)*flowerRadius*dist, sin(angle)*flowerRadius*dist);

      line(0, 0, trackEdge.x, trackEdge.y);
      ellipse(trackCenter.x, trackCenter.y, flowerSize, flowerSize);
      noStroke();
      if (trackAlphas[i]>0) {
        fill(255, trackAlphas[i]*255);
        float targetSize = type == HubType.TRACK?(flowerSize+(cos(millis()/300.f))*flowerSize/4):flowerSize;
        ellipse(trackCenter.x, trackCenter.y, targetSize, targetSize);
      }
      trackCenters[i] = new PVector(trackCenter.x+x, trackCenter.y+y);
      if (showText)
      {
        int txtGray =  int((1.0-trackAlphas[i])*255);
        fill(txtGray);
        textSize(flowerSize*2/3);
        textAlign(CENTER, CENTER);
        //        PVector dir = trackCenter.copy().normalize().mult(flowerSize/2 + 20);
        PVector textPos = trackCenter;//.copy().add(dir);

        text((startTrack+i+1)+"", textPos.x, textPos.y);
      }
    }

    popMatrix();
    popStyle();
  }

  public void disconnect() {
    if (port != null)
    {
      port.clear();
      port.stop();
      port = null;
      isConnected = false;
    }
  }
  public void connect()
  {
    disconnect();

    try
    {
      port = new Serial(parent, portName, 9600); 
      isConnected = true;
      hubColor = hubColors[index % hubColors.length];
    }
    catch(Exception e)
    {
      println("Could not connect to "+portName+" : "+e.getMessage());
      isConnected = false;
      hubColor = color(100, 100, 100);
    }
  }

  public void update()
  {
    processSerial();
  }

  public void processSerial()
  {
    if (!isConnected) return;
    while (port.available () > 0)
    {
      int c = port.read();
      switch(c)
      {
      case 255:
        processBuffer();
        bufferIndex = 0;
        break;

      case 112: //p
        bufferIndex = 0;
        break;

      default:
        if (bufferIndex < 31)
        {
          buffer[bufferIndex] = c;
          bufferIndex++;
        }
      }
    }
  }
  public void setAutoMap(boolean m) {
    if (m) {
      recievedMakeysPins.clear();
      updateAutoMap();
    } else {
    }
    autoMap = m;
  }

  private void updateAutoMap() {
    boolean isTrack = type == HubType.TRACK;
    int trackMul = (isTrack?3:1);
    Collections.sort(recievedMakeysPins);

    for (int i = 0; i < portMap.length; i++) {
      portMap[i] = -1;
    }
    for (int i = 0; i < recievedMakeysPins.size(); i++) {
      int p = recievedMakeysPins.get(i)*trackMul;
      portMap[p] = i*trackMul;
      if (isTrack) {
        portMap[p+1] = portMap[p]+1;
        portMap[p+2] = portMap[p]+2;
      }
    }
    numTracks = recievedMakeysPins.size();
        trackActives = new boolean[numTracks];
    trackVolumes = new float[numTracks];
    trackAlphas = new float[numTracks];
    trackDims = new float[numTracks];
    trackCenters = new PVector[numTracks];
    writeAutoMap();
  }

  private String getMapFileName() {
    String [] sp = splitTokens(portName, "/.");
    String mapName = sp[sp.length-1];
    return "autoMap/"+mapName+".txt";
  }

  private void writeAutoMap() {

    int [] nums = new int[portMap.length];
    for (int i = 0; i < portMap.length; i++) {
      nums[i] = i;
    }
    PrintWriter output = createWriter(getMapFileName());
    output.println(join(nfs(nums, 2), ","));
    output.println(join(nfs(portMap, 2), ","));
    output.flush();
    output.close();
  }

  private void loadAutoMap() {
    recievedMakeysPins.clear();
    String[] outputLines = loadStrings(getMapFileName());
    if (outputLines!=null && outputLines.length>=2) {
      String[] spm = splitTokens(outputLines[1], ",");
      for (int i = 0; i < spm.length; i++) {
        portMap[i] = parseInt(spm[i]);
        if(portMap[i]>=0){
          boolean isTrack = type == HubType.TRACK;
          int trackMul = (isTrack?3:1);
          int tpin =i/trackMul; 
          if (!recievedMakeysPins.contains(tpin)) {
            println("adding ", tpin);
            recievedMakeysPins.add(tpin);
        
          }
        }
      }
      updateAutoMap();
    }
  }
  public void processBuffer()
  {

    int pin = buffer[0];
    int val = buffer[1];
    if (autoMap) {
      boolean isTrack = type == HubType.TRACK;
      int trackMul = (isTrack?3:1);
      int tpin =pin/trackMul; 
      if (!recievedMakeysPins.contains(tpin)) {
        println("adding ", tpin);
        recievedMakeysPins.add(tpin);
        updateAutoMap();
      }
      
      
    }
    
    pin = portMap[pin];
    
    int track = type == HubType.TRACK?floor(pin/3):pin; // if TRIGGER or SWITCH all pins are a trigger track
    int command = type == HubType.TRACK?pin%3:0; //if TRIGGER or SWITCH all pins are a trigger track

    println("Process buffer : "+pin+"("+buffer[0]+") "+"/"+val+"/"+track+"/"+command);

    if (track >= numTracks)
    {
      println("Wrong track : "+track);
      return;
    }

    switch(command)
    {
    case 0: //Mute
      if (val == 1)
      {
        if (type == HubType.TRACK) toggleTrackActive(track);
        else if (type == HubType.TRIGGER) triggerTrack(track);
        else if (type == HubType.SWITCH) switchTrack(track);
      }
      break;

    case 1: //Volume up
      trackDims[track] = (val == 1)?.01f:0f;
      break;

    case 2: //Volume down
      trackDims[track] = (val == 1)?-.01f:0f;
      break;
    }
  }

  public void toggleTrackActive(int index)
  {
    if (type == HubType.TRIGGER) return;
    setTrackActive(index, !trackActives[index]);
  }

  public void setTrackActive(int index, boolean value)
  {
    if (type == HubType.TRIGGER) return;
    trackActives[index] = value;
    trackMuteCallback(startTrack+index, !trackActives[index]);
  }

  public void setTrackVolume(int index, float value)
  {
    if (type == HubType.TRIGGER) return;
    if (!useVolume) return;
    trackVolumes[index] = min(max(value, 0), 1);
    trackVolumeCallback(startTrack+index, trackVolumes[index]);
  }

  public void triggerTrack(int index)
  {
    trackVolumes[index] = 0;
    trackAlphas[index] = 1;
    triggerCallback(startTrack+index);
  }

  public void switchTrack(int index)
  {
    trackActives[index] = !trackActives[index];
    trackMuteCallback(startTrack+index, !trackActives[index]);
  }
}
