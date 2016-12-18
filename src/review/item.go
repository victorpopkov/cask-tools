package review

type Item struct {
	Name   Name
	Values []string
}

type Name struct {
	Value        string
	PluralSuffix string
}

// NewItem returns a new Item instance with a name from provided value. By
// default, the name plural suffix is empty.
func NewItem(name string, a ...interface{}) Item {
	suffix := ""
	if len(a) >= 1 {
		suffix = a[0].(string)
	}

	item := new(Item)
	item.Name.Value = name
	item.Name.PluralSuffix = suffix

	return *item
}

// AddValue adds a new value to the Item.
func (self *Item) AddValue(value string) {
	self.Values = append(self.Values, value)
}

// String returns a string representation of the Name with a plural suffix.
func (self *Name) String() string {
	return self.Value + self.PluralSuffix
}
