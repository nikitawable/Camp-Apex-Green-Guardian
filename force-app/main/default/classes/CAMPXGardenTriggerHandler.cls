/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CAMPXGardenTriggerHandler {
    
    //The ?? operator returns the left-hand argument if the left-hand argument isn’t null. Otherwise, it returns the right-hand argument.
    public static void initializeDefaultValues(List<CAMPX__Garden__c> newGardens)
    {
     	for(CAMPX__Garden__c garden: newGardens)
        {
            garden.CAMPX__Status__c = garden.CAMPX__Status__c??'Awaiting Resources';
            garden.CAMPX__Max_Plant_Count__c = garden.CAMPX__Max_Plant_Count__c??100;
            garden.CAMPX__Minimum_Plant_Count__c = garden.CAMPX__Minimum_Plant_Count__c??1;
            garden.CAMPX__Total_Plant_Count__c = garden.CAMPX__Total_Plant_Count__c??0;
            garden.CAMPX__Total_Unhealthy_Plant_Count__c = garden.CAMPX__Total_Unhealthy_Plant_Count__c??0;
        }
    }
    /**
     * Create a Task for Assigned manager
     */
    public static void createTask(List<CAMPX__Garden__c> gardenList)
    {
		List<CAMPX__Garden__c> gardList = new List<CAMPX__Garden__c>();
        for(CAMPX__Garden__c garden: gardenList)
        {
            if(garden.CAMPX__Manager__c != null)
            {
                gardList.add(garden);	                
            }
        }
        createTaskForGarden(gardList);
    }
    /**
     * Create a task for new Manager, when manager is assigned during update
     */
    public static void createTask(List<CAMPX__Garden__c> gardenList,Map<Id,CAMPX__Garden__c> oldGardenMap)
    {
     	List<CAMPX__Garden__c> gardList = new List<CAMPX__Garden__c>();
        for(CAMPX__Garden__c garden: gardenList)
        {
            if(garden.CAMPX__Manager__c != null && oldGardenMap.get(garden.Id).CAMPX__Manager__c == null)
            {
				gardList.add(garden);	                
            }
        }
        createTaskForGarden(gardList);
    }
    /**
     * Create Task Utility Method
     */
    private static void createTaskForGarden(List<CAMPX__Garden__c> gardenList)
    {
        List<Task> newTaskList = new List<Task>();
        for(CAMPX__Garden__c garden: gardenList)
        {
            Task newtask = new Task();
            newtask.WhatId = garden.Id;
            newTask.OwnerId = garden.CAMPX__Manager__c;
            newTask.Subject = 'Acquire Plants';
            newTaskList.add(newTask);
        }
        insert newTaskList; 
    }
    /**
     * Transfer the task to new manager
     */
    public static void transferTask(List<CAMPX__Garden__c> gardenList,Map<Id,CAMPX__Garden__c> oldGardenMap)
    {
        List<Task> updateTaskList = new List<Task>();
        Map<Id,Id> gardenVsManager = new Map<Id,Id>();
        for(CAMPX__Garden__c garden: gardenList)
        {
            if(garden.CAMPX__Manager__c != null && oldGardenMap.get(garden.Id).CAMPX__Manager__c != null && garden.CAMPX__Manager__c != oldGardenMap.get(garden.Id).CAMPX__Manager__c)
            {
             	   gardenVsManager.put(garden.Id,garden.CAMPX__Manager__c);
            }
        }
        for(Task managetask : [SELECT Id,WhatId,OwnerId FROM task WHERE WhatId In :gardenVsManager.KeySet() AND Status != 'Completed' AND Subject ='Acquire Plants'])
        {
            if(managetask.OwnerId != gardenVsManager.get(managetask.WhatId))
            {
                managetask.OwnerId = gardenVsManager.get(managetask.WhatId);
                updateTaskList.add(managetask);
            }
        }
        update updateTaskList;
    }
    
    /**
     * Delete the task when the manager is removed from the Garden
     */
    public static void deleteTask(List<CAMPX__Garden__c> gardenList,Map<Id,CAMPX__Garden__c> oldGardenMap)
    {
        List<Task> updateTaskList = new List<Task>();
        Set<Id> gardenIds = new Set<Id>();
		for(CAMPX__Garden__c garden : gardenList)
        {
            if(garden.CAMPX__Manager__c == null && oldGardenMap.get(garden.Id).CAMPX__Manager__c != null)
            {
         		gardenIds.add(garden.Id);
            }
        }
         delete [SELECT Id,WhatId,OwnerId FROM task WHERE WhatId In :gardenIds AND Status != 'Completed' AND Subject ='Acquire Plants'];
    }
    /**
     * Assign Working start Date to the new Manager
     */
    public static void assignManagerWorkingDate(List<CAMPX__Garden__c> gardenList,Map<Id,CAMPX__Garden__c> oldGardenmap)
    {
        for(CAMPX__Garden__c garden: gardenList)
        {
            if(oldGardenmap == null)
            {
                if(garden.CAMPX__Manager__c != null)
                {
                    garden.CAMPX__Manager_Start_Date__c = Date.Today();
                }
            }
            else if(garden.CAMPX__Manager__c != null && ((oldGardenmap.get(garden.Id).CAMPX__Manager__c == null) || oldGardenmap.get(garden.Id).CAMPX__Manager__c != null && garden.CAMPX__Manager__c != oldGardenmap.get(garden.Id).CAMPX__Manager__c))
            {
                garden.CAMPX__Manager_Start_Date__c = date.Today();
            }
            else if(garden.CAMPX__Manager__c == null && oldGardenmap.get(garden.Id).CAMPX__Manager__c != null)
            {
                garden.CAMPX__Manager_Start_Date__c = null;
            }
        }
    }
    /**
     * @description Based on Total Plant Count, Max Plant Count, Minimum Plant Count,
     *              calculate the Garden's capacity
     */
    
    public static void calculateCapacity(List<CAMPX__Garden__c> gardens)
    {
        for(CAMPX__Garden__c garden: gardens)
        {
            if(garden.CAMPX__Total_Plant_Count__c == null || garden.CAMPX__Max_Plant_Count__c == null || garden.CAMPX__Total_Plant_Count__c == 0 || garden.CAMPX__Max_Plant_Count__c == 0)
            {
                garden.CAMPX__Capacity__c = 0;
            }
            else
            {
                garden.CAMPX__Capacity__c = (garden.CAMPX__Total_Plant_Count__c/garden.CAMPX__Max_Plant_Count__c)*100;
            }
            garden = gardenStatus(garden);
        }
    }
    /**
     * @description Based on the garden's capacity, update the garden status
     */
    public static CAMPX__Garden__c gardenStatus(CAMPX__Garden__c garden)
    {
        garden = gardenHealthIndex(garden);
        if(garden.CAMPX__Status__c == 'Permanent Closure') {return garden;}
        if((garden.CAMPX__Capacity__c >= 70 && garden.CAMPX__Capacity__c <= 100) && (garden.CAMPX__Total_Plant_Count__c >= garden.CAMPX__Minimum_Plant_Count__c) && (garden.CAMPX__Health_Index__c > = 70))
        {
         	garden.CAMPX__Status__c = 'Operational';   
        }
        else if(garden.CAMPX__Capacity__c == 0)
        {
            garden.CAMPX__Status__c = 'Temporary Closure';
        }
        else if(garden.CAMPX__Capacity__c > 100)
        {
            garden.CAMPX__Status__c = 'Over Capacity';
        }
        else if((garden.CAMPX__Capacity__c < 70 && garden.CAMPX__Capacity__c > 0) || (garden.CAMPX__Health_Index__c < 70) || (garden.CAMPX__Minimum_Plant_Count__c > garden.CAMPX__Total_Plant_Count__c))
        {
            garden.CAMPX__Status__c = 'Awaiting Resources';
        }
        return garden;
    }
    /**
     * @Description calculate garden's Health Index
     */
    public static CAMPX__Garden__c gardenHealthIndex(CAMPX__Garden__c garden)
    {
        if(garden.CAMPX__Total_Plant_Count__c == null || garden.CAMPX__Total_Plant_Count__c == 0)
        {
            garden.CAMPX__Health_Index__c = 0;
        }
        else
        {
            garden.CAMPX__Health_Index__c = ((garden.CAMPX__Total_Plant_Count__c - garden.CAMPX__Total_Unhealthy_Plant_Count__c)/garden.CAMPX__Total_Plant_Count__c) * 100; 
        }
        return garden;
    }
}