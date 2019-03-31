class OSCOutput extends Output
{
  
  public String muteAddress;
  public String volumeAddress;
  public String triggerAddress;
  
  public OSCOutput(int numTracks, String remoteIP, int remotePort, String midiDeviceName)
  {
    super(numTracks,remoteIP,remotePort,midiDeviceName);
    
    println(" > New OSC Output");
    
    muteAddress = "/mute";
    volumeAddress = "/volume";
    triggerAddress = "/trigger";
  }
  
  public  void sendTrackMute(int track, boolean mute)
  {
    if(muteAddress != null && muteAddress.length() == 0) return;
    
     OscMessage m = new OscMessage(muteAddress+track);
    //m.add(track);
    m.add(mute?1:0);
    osc.send(m,remote);
  }
  
  public void sendTrackVolume(int track, float volume)
  {
    if(volumeAddress.length() == 0) return;
    
    OscMessage m = new OscMessage(volumeAddress+track);
    //m.add(track);
    m.add(map(volume,0,1,0,.85));
    osc.send(m,remote);
  }
  
  public void sendTrigger(int trigger)
  {
    if(triggerAddress.length() == 0) return;
    
    OscMessage m = new OscMessage(triggerAddress+trigger);
    ///m.add(trigger);
    osc.send(m,remote);
  }
  
  public void processFB(OscMessage m){
    ParsableAd ad = new ParsableAd(m.addrPattern());
    println("recieved FB"+m.addrPattern());
    if(ad.consume(volumeAddress)){
      println("volume ");
      int num = ad.intNSkip();
      println("volume : "+num);
      hubManager.setTrackVolumeFB(num,m.get(0).floatValue());
    }
    else if(ad.consume(muteAddress)){
      int num = ad.intNSkip();
      hubManager.setTrackActiveFB(num,m.get(0).intValue()>0);
    }

  }
}

  public class ParsableAd {

    private String fullAd;
    private String rem;

    public ParsableAd(String str) {
        this.fullAd = str;
        this.rem = fullAd;
    }

    public boolean consume(String p) {
        if(rem.startsWith(p)){
          rem = rem.substring(p.length());
          return true;
        }
        return false;
    }
    public void skip(){
      int i = rem.indexOf('/');
      rem = rem.substring(i);
    }
    public int intNSkip(){
      int i = rem.indexOf('/');
      if(i==-1){i=rem.length()-1;}
      int res = parseInt(rem.substring(0,i));
      rem = rem.substring(min(rem.length()-1,i+1));
      return res;
    }
    public void reset(){rem = fullAd;}
    public String toString() {return rem;}
    public int toInt(){return parseInt(rem);}

}
