-- Edit unit wounds.
--[====[

gui/wound-editor
===============
An editor for editing a unit's wounds. Made by SlimeOfSteel.
Fuses some elements from GameMaster's gm-editor script.
And yes, I'm aware my code is a mess. I'm only a novice lua programmer.
Constructive criticism and tips are not only welcome, but encouraged.

]====]
local gui = require 'gui'
local dialog = require 'gui.dialogs'
local widgets = require 'gui.widgets'
local guiScript = require 'gui.script'

local unit = dfhack.gui.getSelectedUnit(true)

selwpid = -1

if unit == nil then
	qerror("No unit selected.")
end

-- checks if unit is dead
if unit.flags1["dead"] == true then
	qerror("Unit is dead.")
end

------

woundsc = defclass(wound_screen,gui.FramedScreen)

function woundsc:init(args)
local woundList = widgets.List{view_id="woundList",choices={},frame={t=1,l=1,b=1},on_submit=self:callback("updateWoundLayers")}
local layerList = widgets.List{view_id="layerList",choices={},frame={t=1,l=1,b=1},on_submit=self:callback("updateWoundLayerStatus")}
local layerstatusList = widgets.List{view_id="layerstatusList",choices={},frame={t=1,l=1,b=1},on_submit=self:callback("changeStatusValue")}
--local 

local mp = widgets.Panel{
	subviews={
		woundList,
		widgets.Label{text={{key='CUSTOM_A',text=': Add wound '}},frame = {l=1,b=0}},
		widgets.Label{text={{key='CUSTOM_R',text=': Remove wound '}},frame = {l=15,b=0}}
		
	}}
local layerp = widgets.Panel{subviews={
	layerList,
		widgets.Label{text={{key='CUSTOM_A',text=': Add layer '}},frame = {l=1,b=0}},
		widgets.Label{text={{key='CUSTOM_R',text=': Remove layer '}},frame = {l=15,b=0}}
	}}

local layerfp = widgets.Panel{subviews={
	layerstatusList,
		widgets.Label{text={{key='SELECT',text=': Change value '}},frame = {l=1,b=0}},
	
	}}

local pages = widgets.Pages{subviews={mp,layerp,layerfp},view_id="pages"}
self:addviews{
	pages

}
self:updateWounds()
end

------ 

function woundsc:onInput(keys)
	if keys.LEAVESCREEN_ALL  then
		self:dismiss()
	end
	
	if keys.LEAVESCREEN then 
		if self.subviews.pages:getSelected() == 3 then
			self.subviews.pages:setSelected(2)
		elseif self.subviews.pages:getSelected() == 2 then
			self.subviews.pages:setSelected(1)
		else
			self:dismiss() 
		end
	end
	
	if keys.CUSTOM_A and self.subviews.pages:getSelected() == 1 then
		guiScript.start(function()
			local parts = {}
			local twidt = {}
			
			-- adds wound ids to temporary table for comparison
			-- in the table, the value of the ids are increased by 1, because of the way
			-- lua tables work.
			for x = 1,#unit.body.wounds,1 do
				table.insert(twidt,unit.body.wounds[x - 1].parts[0].body_part_id + 1)
			end
			
			--sorts temporary wound table in numeric order, because it goes off body part ids.
			table.sort(twidt)
			
			local tti = 1
			
			-- checks if wound(s) already exist.
			-- if they do, the wound(s) are not added to the selection list.
			for p = 1,#unit.body.body_plan.body_parts,1 do
				
				if p ~= (twidt[tti]) then
					table.insert(parts,self:getBodyPartString(p - 1))
				else
					tti = tti + 1
				end
			end
			
			local confirm,idSel,selPrompt = guiScript.showListPrompt("Choose Part","Select a body part",nil,parts,nil,true)
			if confirm then
				self:addWound(idSel,0)
			end
		end)
	end
	
	if keys.CUSTOM_R and self.subviews.pages:getSelected() == 1 then
		guiScript.start(function()
			if #self.subviews.woundList:getChoices() == 0 then
				guiScript.showMessage("ERROR","Unit has no wounds to remove.")
			else
				self:removeWound(self.subviews.woundList:getSelected() - 1)
			end
		end)
	end
	
	
	
	self.super.onInput(self,keys)
end

function woundsc:updateWounds()
	if selwpid ~= -1 then selwpid = -1 end
	
	local c = {}
	local wt = unit.body.wounds
	
	for i = 0,#wt - 1, 1 do
		table.insert(c,self:getBodyPartString(wt[i].parts[0].body_part_id))
	end
	
	--table.sort(c)
	self.subviews.woundList:setChoices(c)

end

function woundsc:updateWoundLayers(rid)
	
	selwpid = rid - 1
	local c = {}
	local wt = unit.body.wounds[rid - 1].parts
	
	-- I'm not sure how to explain it, but i'll try. Sometimes the first layer on a wound might have 
	-- layer_idx greater than 0.
	local idxoffset = unit.body.wounds[rid - 1].parts[0].layer_idx
	
	for i = 0,#wt - 1, 1 do
		table.insert(c,self:getBodyPartLayerString(wt[0].body_part_id,(i + idxoffset)))
	end
	self.subviews.layerList:setChoices(c)
	--print(self.subviews.pages:getSelected())
	self.subviews.pages:setSelected(2)
end

function woundsc:updateWoundLayerStatus(rlid)
	local c = self:getStatusTable(rlid)
	local part = unit.body.wounds[selwpid].parts[rlid - 1]
	self.subviews.layerstatusList:setChoices(c)
	self.subviews.pages:setSelected(3)
	
end

function woundsc:placeholder()
	--print("asdf")
	
	print(self.subviews.layerstatusList.selected)
end

function woundsc:getBodyPartsListString()
	local tb = {}
	for i = 0,#unit.body.wounds - 1, 1 do
		table.insert(c,self:getBodyPartLayerString(unit.body.wounds[p].parts[0].body_part_id))
	end 
	return tb
end

function woundsc:getBodyPartStatus(rid)
	return unit.body.components.body_part_status[rid]
end

function woundsc:getBodyPartString(rid)
	return unit.body.body_plan.body_parts[rid].name_singular[0].value
end

function woundsc:getBodyPartLayerString(rid,rlid)
	return unit.body.body_plan.body_parts[rid].layers[rlid].layer_name
end

function woundsc:getBodyPartGlobalLayerId(rid,rlid)
	return unit.body.body_plan.body_parts[rid].layers[rlid].layer_id
end

-- makes a status table.
function woundsc:getStatusTable(rlid)
	-- this seemingly pointless table is actually used for the choice text.
	-- TODO: Make better description types.
	local tabstr={"cut","smashed","scar cut","scar smashed","bruised tendon","strained tendon","torn tendon","bruised ligament","sprained ligament","torn ligament","severed motor nerve","severed sensory nerve","edged damage","smashed apart","major artery torn","spilled guts","edged shake 1","scar edged shake 1","edged shake 2","broken","scar broken","gouged","blunt shake 1","scar blunt shake 1","blunt shake 2","joint bend 1","scar joint bend 1","joint bend 2","compound fracture","is diagnosed","artery","overlapping fracture","needs setting","entire surface","gelded","strain amount","bleeding level","pain level","nausea level","dizziness level","paralysis level","numbness level","swelling level","impairment level"}
	local tm = {}
	
	local part = unit.body.wounds[selwpid].parts[rlid - 1]
	local tstridx = 1
	for kv,v in pairs(part.flags1) do
		table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx])},{gap=1,text=tostring(v)}}})
		tstridx = tstridx + 1
	end
	
	for i = 1,3,1 do
		table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx])},{gap=1,text=tostring(part.flags2[i])}}})
		tstridx = tstridx + 1
	end
	
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 0])},{gap=1,text=tostring(part.strain)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 1])},{gap=1,text=tostring(part.bleeding)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 2])},{gap=1,text=tostring(part.pain)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 3])},{gap=1,text=tostring(part.nausea)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 4])},{gap=1,text=tostring(part.dizziness)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 5])},{gap=1,text=tostring(part.paralysis)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 6])},{gap=1,text=tostring(part.numbness)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 7])},{gap=1,text=tostring(part.swelling)}}})
	table.insert(tm,{text={{text=string.format("%-30s",tabstr[tstridx + 8])},{gap=1,text=tostring(part.impaired)}}})
	return tm
	
end

function woundsc:addWound(rid,rlid)
	unit.body.wounds:insert("#",{new=true})
	
	-- added wound variable 
	local adw = unit.body.wounds[#unit.body.wounds - 1]
	adw.id = #unit.body.wounds
	unit.body.wound_next_id = unit.body.wound_next_id + 1
	adw.parts:insert("#",{new=true})
	adw.parts[0].body_part_id = rid - 1
	adw.parts[0].global_layer_idx = self:getBodyPartGlobalLayerId(rid,rlid)
	adw.parts[0].layer_idx = rlid
	adw.parts[0].effect_type:resize(#adw.parts[0].effect_type + 1)
	adw.parts[0].effect_perc1:resize(#adw.parts[0].effect_perc1 + 1)
	adw.parts[0].effect_perc2:resize(#adw.parts[0].effect_perc2 + 1)
	self:updateWounds()
end

function woundsc:removeWound(rid)
	unit.body.wounds:erase(rid)
	self:updateWounds()
end

function woundsc:changeStatusValue(selid)
	local part = unit.body.wounds[selwpid].parts[self.subviews.layerList.selected - 1]
	local keylist = {"strain","bleeding","pain","nausea","dizziness","paralysis","numbness","swelling","impaired"}
	if selid <= 32 then
		if part.flags1[selid - 1] == true then part.flags1[selid - 1] = false else part.flags1[selid - 1] = true end
	elseif selid > 32 and selid <= 35 then
		if part.flags2[selid - 32] == true then part.flags2[selid - 32] = false else part.flags2[selid - 32] = true end
	elseif selid > 35 then
		
		--print(part[keylist[selid - 35]],keylist[selid - 35])
		
		guiScript.start(function()
			local confirm,new_value = guiScript.showInputPrompt("Enter new value:",nil,3,tostring(part[keylist[selid - 35]]),5)
			if confirm then
				part[keylist[selid - 35]] = new_value
				self:updateWoundLayerStatus(self.subviews.layerList.selected)
			end
		end)
		
	end
	self:updateWoundLayerStatus(self.subviews.layerList.selected)
end


--print(getBodyPartString(0))

woundsc{}:show()
