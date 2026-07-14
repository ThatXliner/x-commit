def price_with_discount(price, customer_type):
    if customer_type == "regular":
        return price
    elif customer_type == "member":
        return price * 0.9
    elif customer_type == "vip":
        return price * 0.8
    elif customer_type == "employee":
        return price * 0.7
    else:
        raise ValueError("unknown customer type: " + customer_type)
