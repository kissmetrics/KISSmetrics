<?
/**
 * Returns true if the passed in user-agent is a robot.
 * 
 * @return boolean  If the current user-agent is a robot
 * @ignore
 */
function is_robot($user_agent)
{
  if ( $user_agent )
  {
    $user_agent = strval($user_agent);
    $user_agent = strtolower($user_agent);

    // We mark something as a bot if it contains any of the $bot_indicators
    // or if it does not contain one of the $browser_indicators. In addition,
    // if the user-agent string contains "mozilla" we make sure it has version
    // information. Finally anything that starts with a word in the $whitelist
    // is never considered a bot.

    $whitelist = array('w3m', 'dillo', 'links', 'elinks', 'lynx');
    foreach($whitelist as $word)
    {
      if ( strpos($user_agent, $word) === 0 )
        return false;
    }

    $bot_indicators = array('bot', 'spider', 'search', 'jeeves', 'crawl', 'seek', 'heritrix', 'slurp', 'thumbnails', 'capture', 'ferret', 'webinator', 'scan', 'retriever', 'accelerator', 'upload', 'digg', 'extractor', 'grub', 'scrub');
    foreach($bot_indicators as $word)
    {
      if ( strpos($user_agent, $word) !== false )
        return true;
    }

    $browser_indicators = array('mozilla', 'browser', 'iphone', 'lynx', 'mobile', 'opera', 'icab');
    $has_browser_indicator = false;

    foreach($browser_indicators as $word)
    {
      if ( strpos($user_agent, $word) !== false )
      {
        $has_browser_indicator = true;
        break;
      }
    }
    if ( !$has_browser_indicator )
      return true;

    // Check for mozilla version information
    if ( strstr($user_agent, 'mozilla') !== false )
    {
      if ( strstr($user_agent, '(') === false )
        return true;
      if ( !preg_match('/mozilla\/\d+/i',$user_agent) )
        return true;
    }

    return false;
  }
  return false;
}
?>
