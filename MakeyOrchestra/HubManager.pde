class HubManager
{
  ArrayList<Hub> hubs;
  PApplet parent;
  boolean autoMap=false;
  public HubManager(PApplet parent)
  {
    this.parent = parent; 
    hubs = new ArrayList<Hub>();
  } 

  public void draw()
  {
    pushStyle();
    pushMatrix();
    translate(width/2, height/2);
    if (gridMode) {
      int numHubs = hubs.size();
      float squareNumSide = ceil(sqrt(numHubs));
      float ar = width*1.0/height;
      float gridXf = squareNumSide*int(ar);
      int gridX = min(numHubs,max(1, ceil(gridXf)));
      int gridY = min(numHubs,max(1, ceil(numHubs/gridXf)));
      float side  = min(width/gridX, height/gridY);
      flowerRadius = int(side/2-flowerSize/2 -8)  ;
      int k  = 0;
      for (int i = 0; i < gridX; i++) {
        for (int j =0; j < gridY; j++) {
          if (k<hubs.size()) {
            hubs.get(k).update();
            hubs.get(k).set((i+0.5 -gridX/2.0)*side, (j+0.5-gridY/2.0)*side);
            hubs.get(k).draw();
            k++;
          }
        }
      }
    } else {

      fill(50);
      ellipseMode(CENTER);

      ellipse(0, 0, globalRadius/3, globalRadius/3);


      for (int i=0; i<hubs.size(); i++)
      {
        float angle = (i*1.f/hubs.size())*PI*2;
        hubs.get(i).update();
        hubs.get(i).set(cos(angle)*globalRadius, sin(angle)*globalRadius);
        hubs.get(i).draw();
      }
    }
    popMatrix();
    popStyle();
  }

  public void reset()
  {
    for (int i=0; i<hubs.size(); i++)
    {
      hubs.get(i).reset();
    }
  }
  
  public void disconnect(){
    println("disconnecting");
    for (int i=0; i<hubs.size(); i++)
    {
      hubs.get(i).disconnect();
    }
  }


  public void addHub(String portName, int startTrack, int numTracks, String type, int[] portMap)
  {
    HubType t = null;
    if (type.equals("track")) t = HubType.TRACK;
    else if (type.equals("trigger")) t = HubType.TRIGGER;
    else if (type.equals("switch")) t = HubType.SWITCH;

    if (t == null)
    {
      println("Hub type unknown : " + type);
      return;
    }

    hubs.add(new Hub(parent, hubs.size(), t, startTrack, numTracks, portName,portMap));
  }
  
  
  public Hub getHubForNum(int n){
    for(int i  = 0 ; i < hubs.size() ; i++){
      Hub h = hubs.get(i);
      if(n>=h.startTrack && n<h.startTrack+h.numTracks){
        return h;
      }
    }
    return null;
  }
  
  
  public void setTrackVolumeFB(int n,float v){
    Hub h = getHubForNum(n);
    if(h!=null){
      h.setTrackVolume(n-h.startTrack,v);
    }
  }
  public void setTrackActiveFB(int n,boolean v){
    Hub h = getHubForNum(n);
    if(h!=null){
      h.setTrackActive(n-h.startTrack,v);
    }
  }
  
  public void toggleAutoMap(){
    autoMap = !autoMap;
    println("toggling automap ",autoMap);
    for(int i  = 0 ; i < hubs.size() ; i++){
      hubs.get(i).setAutoMap(autoMap);
    }
  }
}
