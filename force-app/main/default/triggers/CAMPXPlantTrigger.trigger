trigger CAMPXPlantTrigger on CAMPX__Plant__c (before insert,after insert,after update,after delete) {
    if(Trigger.isInsert && Trigger.isBefore)
    {
        CAMPXPlantTriggerHandler.initializeDefaultValues(Trigger.New);
    }
    if(Trigger.isInsert && Trigger.isAfter)
    {
        CAMPXPlantTriggerHandler.countPlantsInGarden(Trigger.New);
        CAMPXPlantTriggerHandler.countUnhealthyPlants(Trigger.New);
    }
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        CAMPXPlantTriggerHandler.countPlantsInGarden(Trigger.New,Trigger.OldMap);
    }
    if(Trigger.isDelete && Trigger.isAfter)
    {
        CAMPXPlantTriggerHandler.countPlantsForDelete(Trigger.Old);
    }
}