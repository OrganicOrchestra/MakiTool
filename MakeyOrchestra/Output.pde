import oscP5.*;
import netP5.*;
import themidibus.*;

class Output
{  
  NetAddress remote;
  MidiBus midi;
  
  int numTracks;
  
  public Output(int numTracks, String remoteIP, int remotePort, String midiDeviceName)
  {
    remote = new NetAddress(remoteIP,remotePort);
    
    this.numTracks = numTracks;
    
    if(midiDeviceName.length() > 0)
    {
        midi = new MidiBus(this, -1, midiDeviceName);
    }
    
  }
  
  public void init()
  {
    /*
    for(int i=0;i<numTracks;i++)
    {
      sendTrackMute(i,true);
      sendTrackVolume(i,0.85);
    }
    */
  }
 
  public void sendMessage(OscMessage m)
  {
    osc.send(m,remote); 
  }
  
  public void sendMidiNote(int channel, int pitch, int velocity,boolean sendOffAfter)
  {
    if(midi == null)
    {
      println("Send note midi is null");
      return;
    }
    midi.sendNoteOn(channel, pitch, velocity);
    if(sendOffAfter)
    {
      //delay(20);
      midi.sendNoteOff(channel,pitch,0);
    }
  }
  
  
  //FUNCTIONS TO CALL
  public void sendTrackMute(int track, boolean mute)
  {
    //to override
  }
  
  public void sendTrackVolume(int track, float volume)
  {
    //to override
  }
  
  public void sendTrigger(int trigger)
  {
    //to override
  }
  
  public void processFB(OscMessage m){
  }
}
