'use strict';

chrome.runtime.onInstalled.addListener (details) ->
  console.log('previousVersion', details.previousVersion)

chrome.browserAction.setBadgeText({text: 'Hello, World'})
Stat =
  data: {}
  cur: null

lastTime=0
previousData=false
tabChanged = (url) ->
  if Stat.cur
    lst = Stat.data[Stat.cur]
    lst.push(new Date())
  Stat.cur = url
  urlfind = url+''
  urlfind = urlfind.replace(/[^a-zA-Z]/g, '').substring(10, urlfind.length / 2).toLowerCase();
  lst = Stat.data[url] or []
  lst.push(new Date())
  Stat.data[url] = lst
  chrome.storage.local.get ('value') , (data)->
    data=data.value
    size=data.length
    for i in [0..size]
      kl = data[i].key
      if kl == urlfind 
        lastTime =  data[i].value
      else 
        previousData=true
      console.log "And the is result #{lastTime} #{kl} = > #{urlfind}"

calc = (url)->
  lst = Stat.data[url]
  if not lst
    return 0
  n = Math.floor (lst.length / 2)
  res = 0
  for i in [0..n]
    if lst[2 * i + 1] and lst[2 * i]
      res += lst[2 * i + 1].getTime() - lst[2 * i].getTime()
  res += (new Date()).getTime() - lst[lst.length - 1].getTime()
  return res
updateBadge = (url)->
  res = if previousData == true then lastTime else calc url
  previousData=false
  urlfind= Stat.cur
  urlfind=urlfind.replace(/[^a-zA-Z]/g, '').substring(10, urlfind.length / 2).toLowerCase();
  lastTime=res+'';
  result='Olla'

  chrome.storage.local.get ('value') , (result)->
    if typeof(result) == 'object' && !Object.keys(result).length
      many=['key':urlfind, 'value':lastTime]
      chrome.storage.local.set ({'value':many })
      return
    many=result.value
    size=many.length
    find=false
    for i in [0..size]
      kl = many[i].key
      console.log " #{kl} === #{urlfind} #{find}"
      if kl == urlfind 
         many[i].key=urlfind
         many[i].value=lastTime
         find = true
         console.log many
         chrome.storage.local.set ({'value':many }) 
         break
    if find == false
      many[size]=['key':urlfind, 'value':lastTime]
      chrome.storage.local.set ({'value':many }) 
    return

  mm = res % 60
  hh = res // (3600*60000)
  mm = res // (60000)
  ss = parseInt(((res % 60000) / 1000)%60)
  HH = if hh <= 9 then '0'+hh else hh
  MM = if mm <= 9 then '0'+mm else mm
  SS = if ss <= 9 then '0'+ss else ss
  textTime = if hh<=1 then "#{MM}:#{SS}" else "#{HH}:#{MM}:#{SS}"
  return chrome.browserAction.setBadgeText({text: textTime})

chrome.tabs.onActivated.addListener (activeInfo)->
  console.log "Select #{activeInfo.tabId} "
  Stat.curTabId = activeInfo.tabId
  chrome.tabs.get activeInfo.tabId, (tab) ->
    tabChanged(tab.url) if tab.url
    updateBadge tab.url

chrome.alarms.onAlarm.addListener (alarm)->
  if alarm.name == "update"
    if not Stat.curTabId
      return
    chrome.tabs.get Stat.curTabId, (tab)->
      if tab.url
        updateBadge tab.url

chrome.alarms.create("update", {periodInMinutes: 0.010})

console.log('\'Allo \'Allo! Event Page for Browser Action')