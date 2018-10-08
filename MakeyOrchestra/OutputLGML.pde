class LGMLOutput extends OSCOutput
{
  int numPerLoop = 8;
  
  public LGMLOutput(int numTracks, String remoteIP, int remotePort, String midiDeviceName)
  {
    super(numTracks,remoteIP,remotePort,midiDeviceName);
    println("New LGML Output : "+numTracks+" tracks ("+remoteIP+":"+remotePort+")");
    
    muteAddress = "/node/mute";
    volumeAddress = "/live/volume";
    
    
  }
  
  public String getTrackAddr(int track){
    int numLoop = track/numPerLoop + 1;
    int tnum = track%numPerLoop;
    String taddr  ="/node/looper"+numLoop+"/tracks/"+tnum;
    return taddr; 
  }
    //FUNCTIONS TO CALL
  public void sendTrackMute(int track, boolean mute)
  {
    
    String adr = getTrackAddr(track)+"/mute";
     OscMessage m = new OscMessage(adr);
      m.add(mute?1:0);
      sendMessage(m);
  }
  
  public void sendTrackVolume(int track, float volume)
  {
    String adr = getTrackAddr(track)+"/volume";
     OscMessage m = new OscMessage(adr);
      m.add(map(volume,0,1,0,.85));
      sendMessage(m);
  }
  
  public void sendTrigger(int trigger)
  {
    String adr = getTrackAddr(trigger)+"/recorplay";
     OscMessage m = new OscMessage(adr);
     sendMessage(m);
  }
  


  
  public void processFB(OscMessage m){
    ParsableAd ad = new ParsableAd(m.addrPattern());
    
    if(ad.consume("/node/looper")){
      
      int lnum = ad.intNSkip()-1;
      
      if(ad.consume("tracks/")){
        int tnum = ad.intNSkip();
        int mnum = (lnum)*numPerLoop+tnum;
        
        if(ad.consume("mute")){
          hubManager.setTrackActiveFB(mnum,m.get(0).intValue()==0);
        }
        else if (ad.consume("volume")){
          //println("process",ad.toString(),lnum,tnum,mnum);
          hubManager.setTrackVolumeFB(mnum,map(m.get(0).floatValue(),0,0.85,0,1));
      }
      }
      
      
    }
    
  }
}
