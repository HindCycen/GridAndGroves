class_name ExamplePartBehavior extends BlockPartBehavior

func create_action(_block, part):
    print("ExamplePartBehavior executed: ", part.PartDefinition.PartId if part.PartDefinition != null else "?")
    return null
