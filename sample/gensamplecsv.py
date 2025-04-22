import pandas as pd
import random
from faker import Faker
from faker.providers import DynamicProvider


import logging

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    Faker.seed(0)
    fake = Faker()
    account_provider = DynamicProvider(provider_name="account",
        elements=["Cash", "CreditCard", "SavingsBank", "CheckingAccount"],
    )
    expense_provider = DynamicProvider(provider_name="expense",
        elements=["Dinner", "Grocery", "Insurance", "Fuel", "Tax", "Books", "School", "Internet", "Telephone", "House", "Hire"],
    )
    hire_provider = DynamicProvider(provider_name="hire",
        elements=["Cab", "Cleaning", "Accountant", "Driver"],
    )
    income_provider = DynamicProvider(provider_name="income",
        elements=["Salary", "Interest"],
    )
    fake.add_provider(account_provider)
    fake.add_provider(income_provider)
    fake.add_provider(expense_provider)
    fake.add_provider(hire_provider)
    data = []
    for _ in range(10000):
        dt=fake.date_between(start_date='-4y').strftime('%Y-%m-%d')
        ac=fake.account()
        payment = 0
        deposit = 0
        if ac == 'SavingsBank' and 0==random.randint(1,9)%3:
            category = fake.income()
            payee = category
            deposit = random.randint(100,10000)
            if 'Salary' == category:
                deposit = deposit * 15
        else:
            category = fake.expense()
            payment = random.randint(100,10000)
            if category == 'Hire':
                payee = fake.hire()
            else:
                payee = fake.company().replace(',', '') #easier without comma in a csv :)
            payment = random.randint(100,10000)
        net = deposit - payment
        data.append({'id': 'id'+str(fake.unique.random_int(min=111111, max=999999))
                     , 'dt':dt
                     , 'account':ac
                     , 'payee':payee
                     , 'category':category
                     , 'payment':payment
                     , 'deposit':deposit
                     , 'net':net
                     })

    df = pd.DataFrame(data)
    df.dropna(inplace=True)
    df["dt"] = pd.to_datetime(df.dt)
    #These following aren't really used in the dashboards, but 
    #keeping it precalculated for future use.
    df["quarter"] = df.dt.dt.quarter
    df["month"] = df.dt.dt.month
    df["day"] = df.dt.dt.strftime("%a")  # dayofweek gives an integer
    df.sort_values(by=['dt'],inplace=True)
    df.set_index("id", inplace=True)
    df.to_csv("sample.csv")
    logger.info("%80s %6d" % ("TOTAL:", len(df.index)))

