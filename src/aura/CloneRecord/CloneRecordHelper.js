({
    cloneRecord : function(component){
        var recID = component.get("v.originalRecordId");

        console.log("Record ID:"+recID);
        var action = null;
        if(component.get("v.cloneRelatedObjects") == true){
            action = component.get("c.cloneWithRelatedObjects");
        }else{
            action = component.get("c.cloneSingleObject");
        }
        action.setParams({ recordId : recID });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
                var urlEvent = $A.get("e.force:navigateToSObject");
                       urlEvent.setParams({
                           "recordId": response.getReturnValue(),
                           "isredirect": "true"
                       });
                       urlEvent.fire();
            }else if(state === "ERROR"){
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.error("Error Message:"+errors[0].message);
                    }else{
                        console.error("Unknown Error");
                    }
                    showError(component, "Oh!! Internal Server Error.");
                }
            }
        });

        $A.enqueueAction(action);
    },
//"Ohh! We could not clone this record."
    showError: function(component, errMsg){
        console.log('Inside showError');
        $A.get("e.force:closeQuickAction").fire();
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Error: " ,
            "message": errMsg,
            "type":"error"
        });
        resultsToast.fire();
    },

})