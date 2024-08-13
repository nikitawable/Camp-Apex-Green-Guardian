public class CAMPXPlantTriggerHandler {
    //safe navigation operator (?.) to replace explicit, sequential checks for null references. 
    public static void initializeDefaultValues(List<CAMPX__Plant__c> plantList)
    {
        for(CAMPX__Plant__c plant : plantList)
        {
            plant.CAMPX__Soil_Type__c = plant.CAMPX__Soil_Type__c??'All Purpose Potting Soil';
            plant.CAMPX__Water__c = plant.CAMPX__Water__c??'Once Weekly';
            plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__r?.CAMPX__Sun_Exposure__c)??'Partial Sun';
        }
    }
    
    public static void countPlantsInGarden(List<CAMPX__Plant__c> plantList)
    {
        Map<Id,Integer> noOfPlantsInGarden = new Map<Id,Integer>();
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for(CAMPX__Plant__c plant : plantList)
        {
            if(plant.CAMPX__Garden__c != null)
            {
                if(noOfPlantsInGarden.containsKey(plant.CAMPX__Garden__c))
                {
                    Integer count = noOfPlantsInGarden.get(plant.CAMPX__Garden__c) + 1;
                    noOfPlantsInGarden.put(plant.CAMPX__Garden__c,count);
                }
                else
                {
                    noOfPlantsInGarden.put(plant.CAMPX__Garden__c,1);
                }
            }
        }
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Plant_Count__c 
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : noOfPlantsInGarden.KeySet()])
        {
            garden.CAMPX__Total_Plant_Count__c +=  noOfPlantsInGarden.get(garden.Id);
            gardensToUpdate.add(garden);
        }
        update gardensToUpdate;
    }
    
    public static void countPlantsInGarden(List<CAMPX__Plant__c> plantsList, Map<Id, CAMPX__Plant__c> oldPlantsMap)
    {
        Map<Id,Decimal> noOfPlantsInGarden = new Map<Id,Decimal>();
        Map<Id,Decimal> noOfPlantsInGarden2 = new Map<Id,Decimal>();
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for(CAMPX__Plant__c plant: plantsList)
        {
            System.debug(plant.CAMPX__Garden__c);
            System.debug(oldPlantsMap.get(plant.Id).CAMPX__Garden__c);
            if(oldPlantsMap.get(plant.Id).CAMPX__Garden__c != null && (plant.CAMPX__Garden__c == null || oldPlantsMap.get(plant.Id).CAMPX__Garden__c != plant.CAMPX__Garden__c))
            {
                if(noOfPlantsInGarden.containsKey(oldPlantsMap.get(plant.Id).CAMPX__Garden__c))
                {
                    Decimal count = noOfPlantsInGarden.get(oldPlantsMap.get(plant.Id).CAMPX__Garden__c) + 1;
                    noOfPlantsInGarden.put(oldPlantsMap.get(plant.Id).CAMPX__Garden__c,count);
                }
                else
                {
                    noOfPlantsInGarden.put(oldPlantsMap.get(plant.Id).CAMPX__Garden__c,1);
                }
                if(oldPlantsMap.get(plant.Id).CAMPX__Garden__c != plant.CAMPX__Garden__c)
                {
                 	if(noOfPlantsInGarden2.containsKey(plant.CAMPX__Garden__c))
                    {
                        Decimal count = noOfPlantsInGarden2.get(plant.CAMPX__Garden__c) + 1;
                        noOfPlantsInGarden2.put(plant.CAMPX__Garden__c,count);
                    }
                    else
                    {
                        noOfPlantsInGarden2.put(plant.CAMPX__Garden__c,1);
                    }      
                }
            }
        }
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Plant_Count__c 
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : noOfPlantsInGarden.KeySet()])
        {
            Decimal decreasePlantsCount = garden.CAMPX__Total_Plant_Count__c - noOfPlantsInGarden.get(garden.Id);
            garden.CAMPX__Total_Plant_Count__c = decreasePlantsCount;
            gardensToUpdate.add(garden);
        }
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Plant_Count__c 
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : noOfPlantsInGarden2.KeySet()])
        {
            Decimal increasePlantsCount = garden.CAMPX__Total_Plant_Count__c + noOfPlantsInGarden2.get(garden.Id);
            garden.CAMPX__Total_Plant_Count__c = increasePlantsCount;
            gardensToUpdate.add(garden);
        }
        update gardensToUpdate;
        countUnhealthyPlants(plantsList,oldPlantsMap);
    }
    
    public static void countPlantsForDelete(List<CAMPX__Plant__c> plantsList)
    {
        Map<Id, Integer> noOfPlantsRemoved = new Map<Id,Integer>();
        Map<Id, Integer> unHealthyPlantCount = new Map<Id,Integer>();
       for(CAMPX__Plant__c plant: plantsList)
       {
        	if(plant.CAMPX__Garden__c != null)
            {
                if(noOfPlantsRemoved.containsKey(plant.CAMPX__Garden__c))
                {
                    Integer count = noOfPlantsRemoved.get(plant.CAMPX__Garden__c) + 1;
                    noOfPlantsRemoved.put(plant.CAMPX__Garden__c,count);
                }
                else
                {
                   noOfPlantsRemoved.put(plant.CAMPX__Garden__c,1); 
                }
                if(checkPlantStatus(plant) == 'UnHealthy')
                {
                    if(unHealthyPlantCount.containsKey(plant.CAMPX__Garden__c))
                    {
                        Integer count = unHealthyPlantCount.get(plant.CAMPX__Garden__c) + 1;
                        unHealthyPlantCount.put(plant.CAMPX__Garden__c,count);   
                    }
                    else
                    {
						unHealthyPlantCount.put(plant.CAMPX__Garden__c,1);                           
                    }
                }
            }
       }
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Plant_Count__c,
                                       CAMPX__Total_Unhealthy_Plant_Count__c
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : noOfPlantsRemoved.KeySet()])
        {
            garden.CAMPX__Total_Plant_Count__c -=  noOfPlantsRemoved.get(garden.Id);
            if(unHealthyPlantCount.containsKey(garden.Id)) { garden.CAMPX__Total_Unhealthy_Plant_Count__c -= unHealthyPlantCount.get(garden.Id);}
            gardensToUpdate.add(garden);
        }
        update gardensToUpdate;
    }
    
    public static void countUnhealthyPlants(List<CAMPX__Plant__c> plants)
    {
        Map<Id, Integer> gardenToNewCountMap = new Map<Id,Integer>();
        for(CAMPX__Plant__c plant : plants)
        {
            if(!gardenToNewCountMap.containsKey(plant.CAMPX__Garden__c))
            {
                gardenToNewCountMap.put(plant.CAMPX__Garden__c,0);
            }
            if(checkPlantStatus(plant) == 'UnHealthy')
            {
             	Integer count = gardenToNewCountMap.get(plant.CAMPX__Garden__c) + 1;
                gardenToNewCountMap.put(plant.CAMPX__Garden__c, count);   
            }
        }
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Unhealthy_Plant_Count__c 
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : gardenToNewCountMap.KeySet()])
        {
            garden.CAMPX__Total_Unhealthy_Plant_Count__c +=  gardenToNewCountMap.get(garden.Id);
            gardensToUpdate.add(garden);
        }
        update gardensToUpdate;
    }
    
    public static void countUnhealthyPlants(List<CAMPX__Plant__c> plants, Map<Id,CAMPX__Plant__c> oldPlantsMap)
    {
     	Map<Id, Integer> gardenToNewCountMap = new Map<Id,Integer>();
        for(CAMPX__Plant__c plant : plants)
        {
            if(!gardenToNewCountMap.containsKey(plant.CAMPX__Garden__c))
            {
                gardenToNewCountMap.put(plant.CAMPX__Garden__c,0);
            }
            if(checkPlantStatus(plant) == 'UnHealthy'
               && checkPlantStatus(oldPlantsMap.get(plant.Id)) == 'Healthy'
                )
            {
             	Integer count = gardenToNewCountMap.get(plant.CAMPX__Garden__c) + 1;
                gardenToNewCountMap.put(plant.CAMPX__Garden__c, count);
            }
            if(checkPlantStatus(plant) == 'Healthy'
               && checkPlantStatus(oldPlantsMap.get(plant.Id)) == 'UnHealthy'
                )
            {
             	Integer count = gardenToNewCountMap.get(plant.CAMPX__Garden__c) - 1;
                gardenToNewCountMap.put(plant.CAMPX__Garden__c, count);
            }
            if(plant.CAMPX__Garden__c == null && oldPlantsMap.get(plant.Id).CAMPX__Garden__c != null)
            {
             	Integer count = gardenToNewCountMap.get(plant.CAMPX__Garden__c) - 1;
                gardenToNewCountMap.put(plant.CAMPX__Garden__c, count);   
            }
        }
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for(CAMPX__Garden__c garden : [SELECT Id,CAMPX__Total_Unhealthy_Plant_Count__c 
                                       FROM CAMPX__Garden__c 
                                       WHERE Id In : gardenToNewCountMap.KeySet()])
        {
            garden.CAMPX__Total_Unhealthy_Plant_Count__c +=  gardenToNewCountMap.get(garden.Id);
            gardensToUpdate.add(garden);
        }
        update gardensToUpdate;
    }
    
    private static String checkPlantStatus(CAMPX__Plant__c plant)
    {
        return (String.IsNotBlank(plant.CAMPX__Status__c) 
                ? (plant.CAMPX__Status__c == 'Healthy' ? 'Healthy':(plant.CAMPX__Status__c == 'Sick' 
                    || plant.CAMPX__Status__c == 'Wilting' 
                    || plant.CAMPX__Status__c == 'Deceased')? 'UnHealthy':'NoStatus'):'NoStatus');
    }
}