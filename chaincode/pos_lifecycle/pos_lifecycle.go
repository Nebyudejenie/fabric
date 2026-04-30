package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type POSLifecycleChaincode struct {
	contractapi.Contract
}

type Product struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	Owner       string  `json:"owner"`
}

func (p *POSLifecycleChaincode) AddProduct(ctx contractapi.TransactionContextInterface, id, name, description string, price float64, owner string) error {
	product := Product{
		ID:          id,
		Name:        name,
		Description: description,
		Price:       price,
		Owner:       owner,
	}

	productJSON, err := json.Marshal(product)
	if err != nil {
		return fmt.Errorf("failed to marshal product: %v", err)
	}

	return ctx.GetStub().PutState(id, productJSON)
}

func (p *POSLifecycleChaincode) GetProduct(ctx contractapi.TransactionContextInterface, id string) (*Product, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read product: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("product %s does not exist", id)
	}

	var product Product
	if err := json.Unmarshal(productJSON, &product); err != nil {
		return nil, fmt.Errorf("failed to unmarshal product: %v", err)
	}

	return &product, nil
}

func (p *POSLifecycleChaincode) UpdateProduct(ctx contractapi.TransactionContextInterface, id, name, description string, price float64, owner string) error {
	product, err := p.GetProduct(ctx, id)
	if err != nil {
		return err
	}

	product.Name = name
	product.Description = description
	product.Price = price
	product.Owner = owner

	productJSON, err := json.Marshal(product)
	if err != nil {
		return fmt.Errorf("failed to marshal product: %v", err)
	}

	return ctx.GetStub().PutState(id, productJSON)
}

func (p *POSLifecycleChaincode) DeleteProduct(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := p.ProductExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("product %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}

func (p *POSLifecycleChaincode) ProductExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read product: %v", err)
	}

	return productJSON != nil, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&POSLifecycleChaincode{})
	if err != nil {
		panic(fmt.Sprintf("Error creating POSLifecycleChaincode: %v", err))
	}

	if err := chaincode.Start(); err != nil {
		panic(fmt.Sprintf("Error starting POSLifecycleChaincode: %v", err))
	}
}