@LAZYGLOBAL OFF.
pOut("plot_reentry.ks v1.0.0 20170123").

FOR f IN LIST(
  "lib_reentry.ks",
  "lib_transfer.ks",
  "lib_orbit.ks",
  "lib_geo.ks"
) { RUNONCEPATH(loadScript(f)). }


// lib_geo.ks has a function latAtTA() which doesn't seem to be used anywhere.
// I found this logic for calculating the longitude in my notebook, but it never
// made it into a function.
FUNCTION lngAtTATime
{
  PARAMETER o,ta,u_time.

  LOCAL i IS o:INCLINATION.
  LOCAL rel_ta IS mAngle(ta + o:ARGUMENTOFPERIAPSIS).
  LOCAL rel_lng IS rel_ta.
  IF i > 0 {
    SET rel_lng TO ARCSIN(MAX(-1,MIN(1,TAN(latAtTA(o,ta))/TAN(i)))).
    IF rel_ta >= 90 AND rel_ta < 270 { SET rel_lng TO 180 - rel_lng. }
  }
  LOCAL geo_lng IS mAngle(o:LAN + rel_lng - o:BODY:ROTATIONANGLE).

  RETURN mAngle(geo_lng - ((u_time - TIME:SECONDS) * 360 / o:BODY:ROTATIONPERIOD)).
}

// 
// curr_orb - The current orbit patch or that predicted to follow execution of node.
// dest - The planet we are aiming for (usually KERBIN).
// land_ta - The number of degrees beyond the periapsis, where we predict we will land
//           (can pass in negative numbers for cases where we never reach periapsis).
//           This varies depending on both craft and orbit.
//
// based on testing in KSP v1.1.3, suggested values for returning from a moon of Kerbin
// are as follows:
//   command pods: 20
//   probes:       6
// and for a 85km x 29km Kerbin de-orbit:
//   command pods: -30
// These values may need adjusting for the KSP v1.2.2 atmosphere. We had to shift the
// standard de-orbit burn by 20 degrees, suggesting the land_ta is now actually -50
FUNCTION predictReentryForOrbit
{
  PARAMETER curr_orb, dest IS KERBIN, land_ta IS 20.

  LOCAL orb IS curr_orb.
  LOCAL patch_eta_time IS TIME:SECONDS.
  LOCAL count IS orbitReachesBody(curr_orb, dest).
  IF count > 0 {
    SET patch_eta_time TO futureOrbitETATime(curr_orb,count).
    SET orb TO futureOrbit(curr_orb,count).
  }

  LOCAL u_time IS patch_eta_time + 1.

  LOCAL pe_eta_time IS u_time + secondsToTA(SHIP,u_time,0).
  LOCAL pe_spot IS BODY:GEOPOSITIONOF(posAt(SHIP,pe_eta_time)).
  LOCAL pe_lng IS mAngle(pe_spot:LNG - ((pe_eta_time-TIME:SECONDS) * 360 / BODY:ROTATIONPERIOD)).

  LOCAL atm_eta_time IS u_time + secondsToAlt(SHIP,u_time,BODY:ATM:HEIGHT,FALSE).
  LOCAL atm_spot IS BODY:GEOPOSITIONOF(posAt(SHIP,atm_eta_time)).
  LOCAL atm_lng IS mAngle(atm_spot:LNG - ((atm_eta_time-TIME:SECONDS) * 360 / BODY:ROTATIONPERIOD)).

  LOCAL land_eta_time IS pe_eta_time. // not 100% accurate, but won't be far off
  LOCAL land_lat IS latAtTA(orb,land_ta).
  LOCAL land_lng IS lngAtTATime(orb, land_ta, land_eta_time).

  pOut("Re-entry orbit details:").
  pOut("Inc:  " + ROUND(orb:INCLINATION,1) + " degrees.").
  pOut("Ap.:  " + ROUND(orb:APOAPSIS) + "m.").
  pOut("Pe.: " + ROUND(orb:PERIAPSIS) + "m.").
  pOut("Lat (atm interface):  " + ROUND(atm_spot:LAT,1) + " degrees.").
  pOut("Lng (atm interface):  " + ROUND(atm_lng,1) + " degrees.").
  pOut("Lat (periapsis): " + ROUND(pe_spot:LAT,1) + " degrees.").
  pOut("Lng (periapsis): " + ROUND(pe_lng,1) + " degrees.").
  pOut("Lat (landing prediction): " + ROUND(land_lat,1) + " degrees.").
  pOut("Lng (landing prediction): " + ROUND(land_lng,1) + " degrees.").
}

IF HASNODE { predictReentryForOrbit(NEXTNODE:ORBIT). }
ELSE { predictReentryForOrbit(SHIP:ORBIT). }