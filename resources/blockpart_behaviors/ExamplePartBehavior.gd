class_name ExamplePartBehavior extends BlockPartBehavior

func create_action(_block, part):
    print("ExamplePartBehavior executed: ", part.PartId if not part.PartId.is_empty() else "?")
    return null
