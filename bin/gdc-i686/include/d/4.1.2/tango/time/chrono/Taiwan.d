/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.Taiwan;

private import tango.time.chrono.GregorianBased;

/**
 * $(ANCHOR _Taiwan)
 * Represents the Taiwan calendar.
 */
public class Taiwan : GregorianBased 
{
  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override uint id() {
    return TAIWAN;
  }

}

