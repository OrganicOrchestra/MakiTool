class OSCOutput extends Output
{
  
  public String muteAddress;
  public String volumeAddress;
  public String triggerAddress;
  
  public OSCOutput(int numTracks, String remoteIP, int remotePort, String midiDeviceName)
  {
    super(numTracks,remoteIP,remotePort,midiDeviceName);
    
    println(" > New OSC Output");
    
    muteAddress = "/orchestra/mute";
    volumeAddress = "/orchestra/volume";
    triggerAddress = "/orchestra/trigger";
  }
  
  public  void sendTrackMute(int track, boolean mute)
  {
    if(muteAddress != null && muteAddress.length() == 0) return;
    
     OscMessage m = new OscMessage(muteAddress);
    m.add(track);
    m.add(mute?1:0);
    osc.send(m,remote);
  }
  
  public void sendTrackVolume(int track, float volume)
  {
    if(volumeAddress.length() == 0) return;
    
    OscMessage m = new OscMessage(volumeAddress);
    m.add(track);
    m.add(map(volume,0,1,0,.85));
    osc.send(m,remote);
  }
  
  public void sendTrigger(int trigger)
  {
    if(triggerAddress.length() == 0) return;
    
    OscMessage m = new OscMessage(triggerAddress);
    m.add(trigger);
    osc.send(m,remote);
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
      int res = parseInt(rem.substring(0,i));
      rem = rem.substring(min(rem.length()-1,i+1));
      return res;
    }
    public void reset(){rem = fullAd;}
    public String toString() {return rem;}
    public int toInt(){return parseInt(rem);}

}
