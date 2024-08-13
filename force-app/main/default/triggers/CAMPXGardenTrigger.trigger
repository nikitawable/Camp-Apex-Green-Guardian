trigger CAMPXGardenTrigger on CAMPX__Garden__c (before insert,after insert,before update,after update) {
    if(Trigger.isInsert && Trigger.isBefore)
    {
        CAMPXGardenTriggerHandler.initializeDefaultValues(Trigger.New);
        CAMPXGardenTriggerHandler.assignManagerWorkingDate(Trigger.New, null);
        CAMPXGardenTriggerHandler.calculateCapacity(Trigger.New);
    }
    if(Trigger.isInsert && Trigger.isAfter)
    {
        CAMPXGardenTriggerHandler.createTask(Trigger.New);
    }
    if(Trigger.isUpdate && Trigger.isBefore)
    {
        CAMPXGardenTriggerHandler.assignManagerWorkingDate(Trigger.New, Trigger.OldMap);
        CAMPXGardenTriggerHandler.calculateCapacity(Trigger.New);
    }
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        CAMPXGardenTriggerHandler.createTask(Trigger.New,Trigger.oldMap); 
        
        CAMPXGardenTriggerHandler.transferTask(Trigger.New,Trigger.oldMap);
        
        CAMPXGardenTriggerHandler.deleteTask(Trigger.New,Trigger.oldMap); 
    }
}