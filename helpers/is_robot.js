/**
 * Returns true if the passed in user-agent is a robot.
 * 
 * @return boolean  If the current user-agent is a robot
 * @ignore
 */
function is_robot(user_agent)
{
  if ( user_agent )
  {
    user_agent = ''+(user_agent);
    user_agent = user_agent.toLowerCase();

    // We mark something as a bot if it contains any of the bot_indicators
    // or if it does not contain one of the browser_indicators. In addition,
    // if the user-agent string contains "mozilla" we make sure it has version
    // information. Finally anything that starts with a word in the whitelist
    // is never considered a bot.

    var whitelist = ['w3m', 'dillo', 'links', 'elinks', 'lynx'];
    for(var i=0;i<whitelist.length;i++)
    {
      if ( user_agent.indexOf(whitelist[i]) == 0 )
        return false;
    }

    var bot_indicators = ['bot', 'spider', 'search', 'jeeves', 'crawl', 'seek', 'heritrix', 'slurp', 'thumbnails', 'capture', 'ferret', 'webinator', 'scan', 'retriever', 'accelerator', 'upload', 'digg', 'extractor', 'grub', 'scrub'];
    for(var i=0;i<bot_indicators.length;i++)
    {
      if ( user_agent.indexOf(bot_indicators[i]) != -1 )
        return true;
    }

    var browser_indicators = ['mozilla', 'browser', 'iphone', 'lynx', 'mobile', 'opera', 'icab'];
    var has_browser_indicator = false;

    for(var i=0;i<browser_indicators.length;i++)
    {
      if ( user_agent.indexOf(browser_indicators[i]) != -1 )
      {
        has_browser_indicator = true;
        break;
      }
    }
    if ( !has_browser_indicator )
      return true;

    // Check for mozilla version information
    if ( user_agent.indexOf('mozilla') != -1 )
    {
      if ( user_agent.indexOf('(') == -1 )
        return true;

      if ( !user_agent.match(/mozilla\/\d+/) )
        return true;
    }

    return false;
  }
  return false;
};
